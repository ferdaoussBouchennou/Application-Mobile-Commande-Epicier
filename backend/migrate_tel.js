const sequelize = require('./src/config/db');
async function migrate() {
  try {
    await sequelize.query("ALTER TABLE utilisateurs ADD COLUMN telephone VARCHAR(20) DEFAULT NULL");
    console.log("Migration successful");
  } catch (err) {
    if (err.message.includes("Duplicate column name")) {
      console.log("Column already exists");
    } else {
      console.error("Migration failed:", err.message);
    }
  } finally {
    process.exit();
  }
}
migrate();
