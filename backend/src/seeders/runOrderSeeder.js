const seedOrders = require('./orderSeeder');
const sequelize = require('../config/db');

const run = async () => {
  try {
    await seedOrders();
    process.exit(0);
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
};

run();
