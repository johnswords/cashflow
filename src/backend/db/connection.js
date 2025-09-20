const path = require("path");
const fs = require("fs");
const { Kysely, SqliteDialect } = require("kysely");
const Database = require("better-sqlite3");

const DATA_DIR = process.env.DB_DIR || path.join(process.cwd(), "data");
const DB_PATH = process.env.DB_PATH || path.join(DATA_DIR, "cashflow.sqlite");

function ensureDataDirectory() {
  if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
  }
}

ensureDataDirectory();

const sqlite = new Database(DB_PATH);
sqlite.pragma("journal_mode = WAL");
sqlite.pragma("foreign_keys = ON");

const db = new Kysely({
  dialect: new SqliteDialect({ database: sqlite })
});

module.exports = {
  db,
  sqlite,
  DB_PATH
};
