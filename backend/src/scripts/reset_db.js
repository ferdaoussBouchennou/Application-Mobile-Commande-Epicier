const sequelize = require('../config/db');
const User = require('../models/User');
const Store = require('../models/Store');
const Availability = require('../models/Availability');

const resetDatabase = async () => {
  try {
    await sequelize.authenticate();
    console.log('Connexion réussie.');

    // Force la recréation des tables (ATTENTION: supprime les données locales)
    // C'est nécessaire car la table utilisateurs a trop de clés (index) à cause de "alter: true"
    await sequelize.sync({ force: true });
    
    console.log('Base de données réinitialisée avec succès ! ✨');
    console.log('Vous pouvez maintenant lancer le seeder pour retrouver vos données de test.');
    process.exit(0);
  } catch (error) {
    console.error('Erreur lors de la réinitialisation:', error);
    process.exit(1);
  }
};

resetDatabase();
