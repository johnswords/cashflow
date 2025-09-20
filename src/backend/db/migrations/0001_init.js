const { sql } = require("kysely");

exports.up = async db => {
  await db.schema
    .createTable("games")
    .ifNotExists()
    .addColumn("id", "text", col => col.primaryKey())
    .addColumn("title", "text", col => col.notNull())
    .addColumn("status", "text", col => col.notNull().defaultTo("active"))
    .addColumn("created_at", "text", col => col.notNull())
    .addColumn("updated_at", "text", col => col.notNull())
    .addColumn("completed_at", "text")
    .addColumn("winner_player_id", "text")
    .addColumn("winner_comment", "text")
    .addCheckConstraint("games_status_check", sql`status in ('active','completed')`)
    .execute();

  await db.schema
    .createIndex("games_status_idx")
    .ifNotExists()
    .on("games")
    .column("status")
    .execute();

  await db.schema
    .createTable("players")
    .ifNotExists()
    .addColumn("id", "text", col => col.primaryKey())
    .addColumn("game_id", "text", col => col.notNull().references("games.id").onDelete("cascade"))
    .addColumn("name", "text", col => col.notNull())
    .addColumn("color", "text", col => col.notNull())
    .addColumn("sheet_state", "text", col => col.notNull())
    .addColumn("last_modified_at", "text", col => col.notNull())
    .addCheckConstraint(
      "players_color_check",
      sql`color in ('blue','purple','orange','red','green','yellow')`
    )
    .execute();

  await db.schema
    .createIndex("players_game_idx")
    .ifNotExists()
    .on("players")
    .column("game_id")
    .execute();

  await db.schema
    .createTable("audit_log_entries")
    .ifNotExists()
    .addColumn("id", "text", col => col.primaryKey())
    .addColumn("game_id", "text", col => col.notNull().references("games.id").onDelete("cascade"))
    .addColumn("player_id", "text", col => col.notNull().references("players.id").onDelete("cascade"))
    .addColumn("timestamp", "text", col => col.notNull())
    .addColumn("entry_type", "text", col => col.notNull())
    .addColumn("field_paths", "text", col => col.notNull())
    .addColumn("before_snapshot", "text", col => col.notNull())
    .addColumn("after_snapshot", "text", col => col.notNull())
    .addColumn("notes", "text")
    .addColumn("origin_entry_id", "text")
    .addCheckConstraint("audit_entry_type_check", sql`entry_type in ('turn','correction')`)
    .execute();

  await db.schema
    .createIndex("audit_game_idx")
    .ifNotExists()
    .on("audit_log_entries")
    .column("game_id")
    .execute();

  await db.schema
    .createIndex("audit_timestamp_idx")
    .ifNotExists()
    .on("audit_log_entries")
    .column("timestamp")
    .execute();

  await db.schema
    .createTable("leaderboard_records")
    .ifNotExists()
    .addColumn("id", "text", col => col.primaryKey())
    .addColumn("game_id", "text", col => col.notNull().references("games.id").onDelete("cascade"))
    .addColumn("player_id", "text", col => col.notNull().references("players.id").onDelete("cascade"))
    .addColumn("cashflow_value", "real", col => col.notNull())
    .addColumn("captured_at", "text", col => col.notNull())
    .addColumn("winner_comment", "text")
    .execute();

  await db.schema
    .createIndex("leaderboard_cashflow_idx")
    .ifNotExists()
    .on("leaderboard_records")
    .column("cashflow_value")
    .execute();
};

exports.down = async db => {
  await db.schema.dropTable("leaderboard_records").ifExists().execute();
  await db.schema.dropTable("audit_log_entries").ifExists().execute();
  await db.schema.dropTable("players").ifExists().execute();
  await db.schema.dropTable("games").ifExists().execute();
};
