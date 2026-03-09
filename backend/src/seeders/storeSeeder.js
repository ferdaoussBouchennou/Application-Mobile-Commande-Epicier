const bcrypt = require('bcrypt');
const User = require('../models/User');
const Store = require('../models/Store');
const Availability = require('../models/Availability');
const sequelize = require('../config/db');

const seedStores = async () => {
  try {
    await sequelize.sync(); // Ensure tables exist

    // Clear existing data (optional, be careful)
    // await Availability.destroy({ where: {} });
    // await Store.destroy({ where: {} });
    // await User.destroy({ where: { role: 'EPICIER' } });

    const salt = await bcrypt.genSalt(10);
    const password = await bcrypt.hash('Password123', salt);

    const epiciersData = [
      {
        nom: 'Ben Salah',
        prenom: 'Ahmed',
        email: 'ahmed@hanut.com',
        nom_boutique: 'Épicerie Ahmed',
        adresse: 'Rue de la Liberté, Tunis',
        telephone: '0555112233',
        description: 'Produits frais du terroir et épices fines.',
        image_url: 'https://images.unsplash.com/photo-1534723452862-4c874018d66d?q=80&w=500',
        rating: 4.5,
      },
      {
        nom: 'Mansour',
        prenom: 'Sami',
        email: 'sami@hanut.com',
        nom_boutique: 'Hanut Sami',
        adresse: 'Avenue Habib Bourguiba, Sfax',
        telephone: '0555445566',
        description: 'Votre Hanut de quartier ouvert tard le soir.',
        image_url: 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?q=80&w=500',
        rating: 4.2,
      },
      {
        nom: 'Trabelsi',
        prenom: 'Leila',
        email: 'leila@hanut.com',
        nom_boutique: 'Chez Leila',
        adresse: 'Route de la Plage, Hammamet',
        telephone: '0555778899',
        description: 'Fruits de mer et alimentation générale.',
        image_url: 'https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=500',
        rating: 4.8,
      },
      {
        nom: 'Gharbi',
        prenom: 'Karim',
        email: 'karim@hanut.com',
        nom_boutique: 'Karim Market',
        adresse: 'Boulevard de l\'Environnement, Sousse',
        telephone: '0555001122',
        description: 'Le meilleur couscous et produits locaux.',
        image_url: 'https://images.unsplash.com/photo-1574634534894-89d7576c8259?q=80&w=500',
        rating: 3.9,
      },
      {
        nom: 'Zied',
        prenom: 'Mondher',
        email: 'mondher@hanut.com',
        nom_boutique: 'Mondher Express',
        adresse: 'Cité des Jeunes, Bizerte',
        telephone: '0555334455',
        description: 'Rapide, efficace et toujours avec le sourire.',
        image_url: 'https://images.unsplash.com/photo-1583258292688-d0213dc5a3a8?q=80&w=500',
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
        statut_inscription: 'ACCEPTE',
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
    process.exit(0);
  } catch (error) {
    console.error('Error during seeding:', error);
    process.exit(1);
  }
};

seedStores();
