const Router = require("@koa/router");
const { nanoid } = require("nanoid");
const { db } = require("../db/connection");
const { createGameSchema, updatePlayerSchema, appendAuditSchema, endGameSchema } = require("../validators/games");
const { computeCashflow } = require("../utils/cashflow");

const router = new Router({ prefix: "/games" });

const parseJson = (value, fallback = {}) => {
  try {
    return value ? JSON.parse(value) : fallback;
  } catch (err) {
    return fallback;
  }
};

const serializeGameRow = row => ({
  id: row.id,
  title: row.title,
  status: row.status,
  createdAt: row.created_at,
  updatedAt: row.updated_at,
  completedAt: row.completed_at,
  winnerPlayerId: row.winner_player_id,
  winnerComment: row.winner_comment
});

const serializePlayerRow = row => ({
  id: row.id,
  gameId: row.game_id,
  name: row.name,
  color: row.color,
  sheetState: parseJson(row.sheet_state, {}),
  lastModifiedAt: row.last_modified_at
});

const serializeAuditRow = row => ({
  id: row.id,
  gameId: row.game_id,
  playerId: row.player_id,
  timestamp: row.timestamp,
  entryType: row.entry_type,
  fieldPaths: parseJson(row.field_paths, []),
  beforeSnapshot: parseJson(row.before_snapshot, {}),
  afterSnapshot: parseJson(row.after_snapshot, {}),
  notes: row.notes || undefined,
  originEntryId: row.origin_entry_id || undefined
});

const nowIso = () => new Date().toISOString();

const ensureGameExists = async id => {
  const game = await db
    .selectFrom("games")
    .selectAll()
    .where("id", "=", id)
    .executeTakeFirst();

  return game ?? null;
};

const getPlayersForGame = async gameId => {
  const rows = await db
    .selectFrom("players")
    .selectAll()
    .where("game_id", "=", gameId)
    .execute();

  return rows.map(serializePlayerRow);
};

router.get("/", async ctx => {
  const statusFilter = ctx.request.query.status;
  let query = db
    .selectFrom("games")
    .select(["id", "title", "status", "created_at", "updated_at", "completed_at", "winner_player_id", "winner_comment"])
    .orderBy("updated_at", "desc");

  if (statusFilter === "active" || statusFilter === "completed") {
    query = query.where("status", "=", statusFilter);
  }

  const gameRows = await query.execute();
  const gameIds = gameRows.map(row => row.id);

  let playersByGame = new Map();
  if (gameIds.length > 0) {
    const playerRows = await db
      .selectFrom("players")
      .select(["id", "game_id", "name", "color", "sheet_state", "last_modified_at"])
      .where("game_id", "in", gameIds)
      .execute();

    playersByGame = playerRows.reduce((map, row) => {
      const players = map.get(row.game_id) ?? [];
      players.push(serializePlayerRow(row));
      map.set(row.game_id, players);
      return map;
    }, new Map());
  }

  ctx.body = gameRows.map(row => ({
    ...serializeGameRow(row),
    players: playersByGame.get(row.id) ?? []
  }));
});

router.post("/", async ctx => {
  const parsedBody = createGameSchema.safeParse(ctx.request.body ?? {});
  if (!parsedBody.success) {
    ctx.status = 400;
    ctx.body = { errors: parsedBody.error.issues };
    return;
  }

  const { players } = parsedBody.data;
  const title = parsedBody.data.title ?? `Game ${new Date().toLocaleString()}`;
  const timestamp = nowIso();
  const gameId = nanoid(12);
  const playersToInsert = players.map(player => ({
    id: nanoid(12),
    name: player.name,
    color: player.color,
    sheetState: player.sheetState ?? {},
    lastModifiedAt: timestamp
  }));

  await db.transaction().execute(async trx => {
    await trx
      .insertInto("games")
      .values({
        id: gameId,
        title,
        status: "active",
        created_at: timestamp,
        updated_at: timestamp,
        completed_at: null,
        winner_player_id: null,
        winner_comment: null
      })
      .execute();

    await trx
      .insertInto("players")
      .values(
        playersToInsert.map(player => ({
          id: player.id,
          game_id: gameId,
          name: player.name,
          color: player.color,
          sheet_state: JSON.stringify(player.sheetState ?? {}),
          last_modified_at: player.lastModifiedAt
        }))
      )
      .execute();
  });

  ctx.status = 201;
  ctx.body = {
    id: gameId,
    title,
    status: "active",
    createdAt: timestamp,
    updatedAt: timestamp,
    completedAt: null,
    players: playersToInsert.map(player => ({
      id: player.id,
      gameId,
      name: player.name,
      color: player.color,
      sheetState: player.sheetState,
      lastModifiedAt: player.lastModifiedAt
    }))
  };
});

router.get("/:id", async ctx => {
  const gameId = ctx.params.id;
  const gameRow = await db
    .selectFrom("games")
    .selectAll()
    .where("id", "=", gameId)
    .executeTakeFirst();

  if (!gameRow) {
    ctx.status = 404;
    ctx.body = { message: "Game not found" };
    return;
  }

  const players = await getPlayersForGame(gameId);

  ctx.body = {
    ...serializeGameRow(gameRow),
    players
  };
});

router.get("/:id/audit", async ctx => {
  const gameId = ctx.params.id;
  const limit = Math.min(Number(ctx.request.query.limit ?? 50), 200);
  const offset = Number(ctx.request.query.offset ?? 0);

  const gameExists = await ensureGameExists(gameId);
  if (!gameExists) {
    ctx.status = 404;
    ctx.body = { message: "Game not found" };
    return;
  }

  const auditRows = await db
    .selectFrom("audit_log_entries")
    .selectAll()
    .where("game_id", "=", gameId)
    .orderBy("timestamp", "desc")
    .limit(limit)
    .offset(offset)
    .execute();

  ctx.body = auditRows.map(serializeAuditRow);
});

router.post("/:id/audit", async ctx => {
  const gameId = ctx.params.id;
  const parsedBody = appendAuditSchema.safeParse(ctx.request.body ?? {});

  if (!parsedBody.success) {
    ctx.status = 400;
    ctx.body = { errors: parsedBody.error.issues };
    return;
  }

  const { playerId, ...audit } = parsedBody.data;
  const timestamp = audit.timestamp ?? nowIso();

  const playerRow = await db
    .selectFrom("players")
    .select(["id", "game_id"])
    .where("id", "=", playerId)
    .where("game_id", "=", gameId)
    .executeTakeFirst();

  if (!playerRow) {
    ctx.status = 404;
    ctx.body = { message: "Player not found in game" };
    return;
  }

  await db.transaction().execute(async trx => {
    await trx
      .insertInto("audit_log_entries")
      .values({
        id: nanoid(12),
        game_id: gameId,
        player_id: playerId,
        timestamp,
        entry_type: audit.entryType,
        field_paths: JSON.stringify(audit.fieldPaths),
        before_snapshot: JSON.stringify(audit.beforeSnapshot ?? {}),
        after_snapshot: JSON.stringify(audit.afterSnapshot ?? {}),
        notes: audit.notes ?? null,
        origin_entry_id: audit.originEntryId ?? null
      })
      .execute();

    await trx.updateTable("games").set({ updated_at: timestamp }).where("id", "=", gameId).execute();
  });

  ctx.status = 201;
  ctx.body = { ok: true };
});

router.get("/:id/players/:playerId", async ctx => {
  const { id: gameId, playerId } = ctx.params;

  const playerRow = await db
    .selectFrom("players")
    .selectAll()
    .where("game_id", "=", gameId)
    .where("id", "=", playerId)
    .executeTakeFirst();

  if (!playerRow) {
    ctx.status = 404;
    ctx.body = { message: "Player not found" };
    return;
  }

  ctx.body = serializePlayerRow(playerRow);
});

router.patch("/:id/players/:playerId", async ctx => {
  const { id: gameId, playerId } = ctx.params;
  const parsedBody = updatePlayerSchema.safeParse(ctx.request.body ?? {});

  if (!parsedBody.success) {
    ctx.status = 400;
    ctx.body = { errors: parsedBody.error.issues };
    return;
  }

  const playerRow = await db
    .selectFrom("players")
    .selectAll()
    .where("game_id", "=", gameId)
    .where("id", "=", playerId)
    .executeTakeFirst();

  if (!playerRow) {
    ctx.status = 404;
    ctx.body = { message: "Player not found" };
    return;
  }

  const { sheetState, audit } = parsedBody.data;
  const timestamp = audit.timestamp ?? nowIso();

  await db.transaction().execute(async trx => {
    await trx
      .updateTable("players")
      .set({
        sheet_state: JSON.stringify(sheetState ?? {}),
        last_modified_at: timestamp
      })
      .where("game_id", "=", gameId)
      .where("id", "=", playerId)
      .execute();

    await trx
      .insertInto("audit_log_entries")
      .values({
        id: nanoid(12),
        game_id: gameId,
        player_id: playerId,
        timestamp,
        entry_type: audit.entryType,
        field_paths: JSON.stringify(audit.fieldPaths),
        before_snapshot: JSON.stringify(audit.beforeSnapshot ?? {}),
        after_snapshot: JSON.stringify(audit.afterSnapshot ?? {}),
        notes: audit.notes ?? null,
        origin_entry_id: audit.originEntryId ?? null
      })
      .execute();

    await trx.updateTable("games").set({ updated_at: timestamp }).where("id", "=", gameId).execute();
  });

  ctx.body = {
    id: playerRow.id,
    gameId,
    name: playerRow.name,
    color: playerRow.color,
    sheetState,
    lastModifiedAt: timestamp
  };
});

router.post("/:id/end", async ctx => {
  const gameId = ctx.params.id;
  const parsedBody = endGameSchema.safeParse(ctx.request.body ?? {});

  if (!parsedBody.success) {
    ctx.status = 400;
    ctx.body = { errors: parsedBody.error.issues };
    return;
  }

  const gameRow = await db
    .selectFrom("games")
    .selectAll()
    .where("id", "=", gameId)
    .executeTakeFirst();

  if (!gameRow) {
    ctx.status = 404;
    ctx.body = { message: "Game not found" };
    return;
  }

  if (gameRow.status === "completed") {
    ctx.status = 409;
    ctx.body = { message: "Game already completed" };
    return;
  }

  const players = await getPlayersForGame(gameId);
  const winnerPlayer = players.find(player => player.id === parsedBody.data.winnerPlayerId);

  if (!winnerPlayer) {
    ctx.status = 400;
    ctx.body = { message: "Winner player not found in game" };
    return;
  }

  const timestamp = nowIso();
  const cashflowValue = computeCashflow(winnerPlayer.sheetState);

  await db.transaction().execute(async trx => {
    await trx
      .updateTable("games")
      .set({
        status: "completed",
        completed_at: timestamp,
        updated_at: timestamp,
        winner_player_id: parsedBody.data.winnerPlayerId,
        winner_comment: parsedBody.data.winnerComment ?? null
      })
      .where("id", "=", gameId)
      .execute();

    await trx
      .insertInto("leaderboard_records")
      .values({
        id: nanoid(12),
        game_id: gameId,
        player_id: parsedBody.data.winnerPlayerId,
        cashflow_value: cashflowValue,
        captured_at: timestamp,
        winner_comment: parsedBody.data.winnerComment ?? null
      })
      .execute();
  });

  ctx.body = {
    id: gameRow.id,
    title: gameRow.title,
    status: "completed",
    completedAt: timestamp,
    winnerPlayerId: parsedBody.data.winnerPlayerId,
    winnerComment: parsedBody.data.winnerComment ?? null,
    winnerCashflow: cashflowValue
  };
});

module.exports = router;
