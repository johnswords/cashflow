const path = require("path");
const { promises: fs } = require("fs");
const { FileMigrationProvider, Migrator } = require("kysely");
const { db, sqlite } = require("./connection");

async function migrateToLatest() {
  const migrationFolder = path.join(__dirname, "migrations");
  const migrator = new Migrator({
    db,
    provider: new FileMigrationProvider({ fs, path, migrationFolder })
  });

  const { error, results } = await migrator.migrateToLatest();

  results?.forEach(result => {
    if (result.status === "Success") {
      console.log(`Migration ${result.migrationName} executed`);
    } else if (result.status === "Error") {
      console.error(`Migration ${result.migrationName} failed`);
    }
  });

  if (error) {
    console.error(error);
    process.exitCode = 1;
  }

  await db.destroy();
  sqlite.close();
}

migrateToLatest();
