const Store = require('../models/Store');
const Availability = require('../models/Availability');
const sequelize = require('../config/db');

const fixData = async () => {
  try {
    await sequelize.authenticate();
    console.log('Connexion à la base de données réussie.');

    const stores = await Store.findAll();
    console.log(`Traitement de ${stores.length} épiceries...`);

    // Utilisation de l'image locale transférée dans le dossier uploads
    const localHanoutImage = 'uploads/Moul-hanoute-epiciers.jpg';

    for (const store of stores) {
      // 1. Remplacer toutes les images par celle fournie par l'utilisateur
      store.image_url = localHanoutImage;
      await store.save();
      console.log(`Image mise à jour pour: ${store.nom_boutique}`);

      // 2. Fix missing availabilities
      const count = await Availability.count({ where: { epicier_id: store.id } });
      if (count === 0) {
        const jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
        for (const jour of jours) {
          await Availability.create({
            epicier_id: store.id,
            jour: jour,
            heure_debut: '08:00:00',
            heure_fin: '22:00:00'
          });
        }
        console.log(`Horaires ajoutés pour: ${store.nom_boutique}`);
      }
    }

    console.log('Correction terminée ! ✨');
    process.exit(0);
  } catch (error) {
    console.error('Erreur lors de la correction:', error);
    process.exit(1);
  }
};

fixData();
