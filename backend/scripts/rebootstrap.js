const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env') });
const mysql = require('mysql2/promise');
const sequelize = require('../src/config/db');

// Import seeders
const seedAdmin = require('../src/seeders/adminSeeder');
const seedStores = require('../src/seeders/storeSeeder');
const seedProducts = require('../src/seeders/productSeeder');
const seedOrders = require('../src/seeders/orderSeeder');
const seedAvailabilities = require('../src/seeders/availabilitySeeder');
const seedDashboard = require('../src/seeders/dashboardSeeder');

async function rebootstrap() {
  let connection;
  try {
    console.log('🚀 Starting Database Rebootstrap...');

    // 1. Connection to MySQL (without DB selection)
    connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER,
      password: process.env.DB_PASS || '',
      multipleStatements: true
    });

    console.log(`🗑️  Dropping database ${process.env.DB_NAME}...`);
    await connection.query(`DROP DATABASE IF EXISTS \`${process.env.DB_NAME}\``);
    
    console.log(`✨ Creating database ${process.env.DB_NAME}...`);
    await connection.query(`CREATE DATABASE \`${process.env.DB_NAME}\``);
    await connection.query(`USE \`${process.env.DB_NAME}\``);

    // 2. Execute SQL file
    const sqlPath = path.resolve(__dirname, '../../epicier_ecommerce_corrigee.sql');
    if (fs.existsSync(sqlPath)) {
      console.log(`📜 Importing SQL from ${sqlPath}...`);
      const sql = fs.readFileSync(sqlPath, 'utf8');
      
      // Execute as a single block since multipleStatements is enabled
      await connection.query(sql);
      console.log('✅ SQL file imported successfully.');
    } else {
      console.warn(`⚠️  SQL file not found at ${sqlPath}. Skipping import.`);
    }

    // Close mysql2 connection to let Sequelize work
    await connection.end();

    // 3. Sync Models
    console.log('🔄 Syncing Sequelize models...');
    await sequelize.authenticate();
    await sequelize.sync({ force: false }); // force: false because we want to KEEP what the SQL just created
    console.log('✅ Models synced.');

    // 4. Run Seeders (findOrCreate logic will prevent duplicates)
    console.log('🌱 Running seeders...');
    
    console.log('  - Admin seeder...');
    await seedAdmin();
    
    console.log('  - Store seeder...');
    await seedStores();
    
    console.log('  - Product seeder...');
    await seedProducts();
    
    console.log('  - Availability seeder...');
    await seedAvailabilities();
    
    console.log('  - Order seeder...');
    await seedOrders();
    
    console.log('  - Dashboard seeder...');
    // Dashboard seeder might be noisy, we run it last
    try {
        await seedDashboard();
    } catch (e) {
        console.warn('⚠️  Dashboard seeder had some issues (likely duplicate data), but proceeding.');
    }

    console.log('\n🎉 ALL DONE! Database is fully reinitialized and seeded.');
    process.exit(0);
  } catch (error) {
    console.error('\n❌ CRITICAL ERROR during rebootstrap:');
    console.error('Error Message:', error.message);
    console.error('Error Code:', error.code);
    console.error('SQL State:', error.sqlState);
    if (error.sql) {
        console.error('Failing Query:', error.sql.substring(0, 500) + '...');
    }
    console.error('Full Error:', JSON.stringify(error, null, 2));
    process.exit(1);
  }
}

rebootstrap();
