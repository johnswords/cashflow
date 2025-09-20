const Router = require("@koa/router");
const { db } = require("../db/connection");

const router = new Router({ prefix: "/leaderboard" });

const parseLimit = value => {
  if (!value) return 20;
  const parsed = Number(value);
  if (Number.isNaN(parsed) || parsed <= 0) return 20;
  return Math.min(parsed, 100);
};

router.get("/", async ctx => {
  const limit = parseLimit(ctx.request.query.limit);
  const since = ctx.request.query.since;

  let query = db
    .selectFrom("leaderboard_records as lr")
    .innerJoin("players as p", "p.id", "lr.player_id")
    .innerJoin("games as g", "g.id", "lr.game_id")
    .select([
      "lr.id as id",
      "lr.cashflow_value as cashflow_value",
      "lr.captured_at as captured_at",
      "lr.winner_comment as winner_comment",
      "p.name as player_name",
      "p.color as player_color",
      "p.game_id as game_id",
      "g.title as game_title",
      "g.completed_at as completed_at"
    ])
    .where("g.status", "=", "completed")
    .orderBy("lr.cashflow_value", "desc")
    .orderBy("lr.captured_at", "asc")
    .limit(limit);

  if (since) {
    query = query.where("lr.captured_at", ">=", since);
  }

  const rows = await query.execute();

  let currentRank = 0;
  let lastScore = null;

  const leaderboard = rows.map((row, index) => {
    if (lastScore === null || row.cashflow_value !== lastScore) {
      currentRank = index + 1;
      lastScore = row.cashflow_value;
    }

    return {
      id: row.id,
      rank: currentRank,
      player: {
        name: row.player_name,
        color: row.player_color
      },
      game: {
        id: row.game_id,
        title: row.game_title,
        completedAt: row.completed_at
      },
      cashflowValue: row.cashflow_value,
      capturedAt: row.captured_at,
      winnerComment: row.winner_comment || undefined
    };
  });

  ctx.body = leaderboard;
});

module.exports = router;
