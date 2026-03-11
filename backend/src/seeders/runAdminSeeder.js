require('dotenv').config();
const sequelize = require('../config/db');
const seedAdmin = require('./adminSeeder');

const run = async () => {
  try {
    await sequelize.authenticate();
    console.log('Connexion à la base de données réussie.');
    
    await seedAdmin();
    
    console.log('Seeder Admin terminé.');
    process.exit(0);
  } catch (error) {
    console.error('Erreur:', error);
    process.exit(1);
  }
};

run();
