const Store = require('../models/Store');
const Availability = require('../models/Availability');
const sequelize = require('../config/db');

const seedAvailabilities = async () => {
  try {
    await sequelize.authenticate();
    console.log('Connexion à la base de données réussie.');

    const stores = await Store.findAll();
    
    if (stores.length === 0) {
      console.log('Aucun épicier trouvé dans la base de données. Lancez d\'abord storeSeeder.js');
      process.exit(0);
    }

    const jours = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];

    for (const store of stores) {
      console.log(`Traitement des disponibilités pour : ${store.nom_boutique}`);
      
      for (const jour of jours) {
        // Supprimer les anciennes disponibilités pour éviter les doublons si on relance le script
        await Availability.destroy({ 
          where: { 
            epicier_id: store.id,
            jour: jour
          } 
        });

        const estDimanche = jour === 'dimanche';
        
        await Availability.create({
          epicier_id: store.id,
          jour: jour,
          heure_debut: estDimanche ? '09:00:00' : '08:00:00',
          heure_fin: estDimanche ? '14:00:00' : '22:00:00'
        });
      }
    }

    console.log('Table disponibilites remplie avec succès ! 🕒');
    process.exit(0);
  } catch (error) {
    console.error('Erreur lors du remplissage des disponibilités :', error);
    process.exit(1);
  }
};

seedAvailabilities();
