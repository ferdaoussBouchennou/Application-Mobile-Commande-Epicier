const User = require('../models/User');

const seedAdmin = async () => {
  try {
    const adminExists = await User.findOne({ where: { email: 'admin@gmail.com' } });
    
    if (!adminExists) {
      await User.create({
        nom: 'Admin',
        prenom: 'System',
        email: 'admin@gmail.com',
        mdp: '12345678',
        role: 'ADMIN',
        statut_inscription: 'ACCEPTE',
        is_active: true
      });
      console.log('✅ Compte Admin créé avec succès !');
      console.log('📧 Email: admin@gmail.com');
      console.log('🔑 MDP: 12345678');
    } else {
      console.log('ℹ️ Le compte Admin existe déjà.');
    }
  } catch (error) {
    console.error('❌ Erreur lors du seeding de l\'admin:', error);
    throw error;
  }
};

module.exports = seedAdmin;

if (require.main === module) {
  seedAdmin()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}
