const bcrypt = require('bcrypt');
const User = require('../models/User');
const Store = require('../models/Store');
const Availability = require('../models/Availability');
const sequelize = require('../config/db');

const seedStores = async () => {
  try {
    const epiciersData = [
      {
        nom: 'Ben Salah',
        prenom: 'Ahmed',
        email: 'ahmed@hanut.com',
        nom_boutique: 'Épicerie Ahmed',
        adresse: 'Rue de la Liberté, Tunis',
        telephone: '0555112233',
        description: 'Produits frais, lait, pain et alimentation générale.',
        image_url: 'uploads/Moul-hanoute-epiciers.jpg',
        rating: 4.5,
      },
      {
        nom: 'Mansour',
        prenom: 'Sami',
        email: 'sami@hanut.com',
        nom_boutique: 'Hanut Sami',
        adresse: 'Avenue Habib Bourguiba, Sfax',
        telephone: '0555445566',
        description: 'Votre Hanut de quartier : pain chaud et lait tous les matins.',
        image_url: 'uploads/Moul-hanoute-epiciers.jpg',
        rating: 4.2,
      },
      {
        nom: 'Trabelsi',
        prenom: 'Leila',
        email: 'leila@hanut.com',
        nom_boutique: 'Chez Leila',
        adresse: 'Route de la Plage, Hammamet',
        telephone: '0555778899',
        description: 'Alimentation générale and produits de première nécessité.',
        image_url: 'uploads/Moul-hanoute-epiciers.jpg',
        rating: 4.8,
      },
      {
        nom: 'Gharbi',
        prenom: 'Karim',
        email: 'karim@hanut.com',
        nom_boutique: 'Karim Market',
        adresse: 'Boulevard de l\'Environnement, Sousse',
        telephone: '0555001122',
        description: 'Épicerie fine, semoule, huile and pain traditionnel.',
        image_url: 'uploads/Moul-hanoute-epiciers.jpg',
        rating: 3.9,
      },
      {
        nom: 'Zied',
        prenom: 'Mondher',
        email: 'mondher@hanut.com',
        nom_boutique: 'Mondher Express',
        adresse: 'Cité des Jeunes, Bizerte',
        telephone: '0555334455',
        description: 'Service rapide : lait, sucre, pain and plus.',
        image_url: 'uploads/Moul-hanoute-epiciers.jpg',
        rating: 4.0,
      }
    ];

    for (const data of epiciersData) {
      // Check if user already exists
      const existingUser = await User.findOne({ where: { email: data.email } });
      if (existingUser) continue;

      const user = await User.create({
        nom: data.nom,
        prenom: data.prenom,
        email: data.email,
        mdp: 'Password123', // hooks will hash it
        role: 'EPICIER',
        is_active: true
      });

      const store = await Store.create({
        utilisateur_id: user.id,
        nom_boutique: data.nom_boutique,
        adresse: data.adresse,
        telephone: data.telephone,
        description: data.description,
        image_url: data.image_url,
        rating: data.rating,
        statut_inscription: 'ACCEPTE',
        is_active: true
      });

      // Add dummy availabilities
      const jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi'];
      for (const jour of jours) {
        await Availability.create({
          epicier_id: store.id,
          jour: jour,
          heure_debut: '08:00:00',
          heure_fin: '22:00:00'
        });
      }
      // Dimanche
      await Availability.create({
        epicier_id: store.id,
        jour: 'dimanche',
        heure_debut: '09:00:00',
        heure_fin: '14:00:00'
      });
    }

    console.log('Seed completed successfully! 🌱');
  } catch (error) {
    console.error('Error during seeding stores:', error);
    throw error;
  }
};

module.exports = seedStores;

if (require.main === module) {
  seedStores()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}