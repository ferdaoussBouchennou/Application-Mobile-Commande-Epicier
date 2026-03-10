const Category = require('../models/Category');
const Product = require('../models/Product');
const Store = require('../models/Store');
const sequelize = require('../config/db');

const seedProducts = async () => {
  try {
    await sequelize.authenticate();
    console.log('Connexion réussie.');

    // 1. Create Categories from UI Design
    const categoriesData = [
      { nom: 'Huiles' },
      { nom: 'Confiserie' },
      { nom: 'Farines' },
      { nom: 'Conserves' },
      { nom: 'Laitiers' },
      { nom: 'Hygiène' },
      { nom: 'Boissons' },
      { nom: 'Épices' },
      { nom: 'Boulangerie' }
    ];

    const categories = [];
    for (const cat of categoriesData) {
      const [category] = await Category.findOrCreate({ where: { nom: cat.nom } });
      categories.push(category);
    }
    console.log('Catégories créées ou déjà existantes.');

    // 2. Get Stores
    const stores = await Store.findAll();
    if (stores.length === 0) {
      console.error('Aucune boutique trouvée. Veuillez d\'abord lancer storeSeeder.js');
      process.exit(1);
    }

    // 3. Create Products (Moroccan Market Staples)
    const productsData = [
      // Huiles
      { nom: 'Huile Lesieur 1L', prix: 19.50, description: 'Huile de table raffinée Lesieur.', categorie: 'Huiles', image: '/uploads/huiles/lesieur.jpg' },
      { nom: 'Huile d\'Olive Oued Souss 1L', prix: 85.00, description: 'Huile d\'olive extra vierge du Maroc.', categorie: 'Huiles', image: '/uploads/huiles/oued_souss.jpg' },
      { nom: 'Huile Argan Alimentaire 250ml', prix: 120.00, description: 'Huile d\'argan pure et certifiée.', categorie: 'Huiles', image: '/uploads/huiles/argan.jpg' },
      
      // Laitiers
      { nom: 'Lait Centrale 1L', prix: 7.00, description: 'Lait frais pasteurisé Centrale Danone.', categorie: 'Laitiers', image: '/uploads/laitiers/centrale.jpg' },
      { nom: 'Yaourt Jaouda Fraise', prix: 2.50, description: 'Yaourt crémeux aux morceaux de fruits.', categorie: 'Laitiers', image: '/uploads/laitiers/jaouda_fraise.jpg' },
      { nom: 'Raibi Jamila', prix: 2.50, description: 'Boisson lactée fermentée iconique.', categorie: 'Laitiers', image: '/uploads/laitiers/raibi.jpg' },
      { nom: 'Fromage La Vache Qui Rit (16p)', prix: 18.00, description: 'Portions de fromage fondu.', categorie: 'Laitiers', image: '/uploads/laitiers/vache_qui_rit.jpg' },
      
      // Farines & Céréales
      { nom: 'Farine Mouna 5kg', prix: 35.00, description: 'Farine de blé tendre de luxe.', categorie: 'Farines', image: '/uploads/farines/mouna.jpg' },
      { nom: 'Semoule Fine Al Ittihad 1kg', prix: 13.00, description: 'Semoule de blé dur pour couscous.', categorie: 'Farines', image: '/uploads/farines/semoule.jpg' },
      { nom: 'Couscous Dari 1kg', prix: 15.00, description: 'Couscous marocain précuit.', categorie: 'Farines', image: '/uploads/farines/dari.jpg' },

      // Conserves
      { nom: 'Thon Mario à l\'huile', prix: 15.00, description: 'Morceaux de thon de qualité.', categorie: 'Conserves', image: '/uploads/conserves/mario.jpg' },
      { nom: 'Tomate Aïcha 400g', prix: 11.00, description: 'Double concentré de tomate Aïcha.', categorie: 'Conserves', image: '/uploads/conserves/aicha.jpg' },
      { nom: 'Confiture Aïcha Fraise', prix: 16.00, description: 'Confiture de fraises extra.', categorie: 'Conserves', image: '/uploads/conserves/confiture.jpg' },
      
      // Boissons
      { nom: 'Eau Sidi Ali 1.5L', prix: 6.00, description: 'Eau minérale naturelle Sidi Ali.', categorie: 'Boissons', image: '/uploads/boissons/sidi_ali.jpg' },
      { nom: 'Eau Gazeuse Oulmès 1L', prix: 8.50, description: 'Eau minérale gazeuse naturelle.', categorie: 'Boissons', image: '/uploads/boissons/oulmes.jpg' },
      { nom: 'Poms', prix: 6.00, description: 'Boisson rafraîchissante à la pomme.', categorie: 'Boissons', image: '/uploads/boissons/poms.jpg' },
      { nom: 'Thé Sultan (Grain Vert)', prix: 14.00, description: 'Thé vert de qualité supérieure.', categorie: 'Boissons', image: '/uploads/boissons/the_sultan.jpg' },

      // Boulangerie Traditional
      { nom: 'Pain Batbout (Unité)', prix: 1.50, description: 'Petit pain traditionnel marocain.', categorie: 'Boulangerie', image: '/uploads/boulangerie/batbout.jpg' },
      { nom: 'Msemen nature', prix: 2.00, description: 'Crêpe feuilletée marocaine.', categorie: 'Boulangerie', image: '/uploads/boulangerie/msemen.jpg' },
      { nom: 'Baghrir (Unité)', prix: 1.50, description: 'Crêpe mille trous.', categorie: 'Boulangerie', image: '/uploads/boulangerie/baghrir.jpg' },

      // Confiserie
      { nom: 'Biscuits Henry\'s', prix: 1.00, description: 'Biscuits secs traditionnels.', categorie: 'Confiserie', image: '/uploads/confiserie/henrys.jpg' },
      { nom: 'Merendina Classic', prix: 2.00, description: 'Génoise enrobée de chocolat.', categorie: 'Confiserie', image: '/uploads/confiserie/merendina.jpg' },
      
      // Hygiène
      { nom: 'Savon El Kef', prix: 4.50, description: 'Savon de marseille traditionnel.', categorie: 'Hygiène', image: '/uploads/hygiene/elkef.jpg' },
      { nom: 'Détergent Magix 1kg', prix: 22.00, description: 'Lessive poudre pour machine.', categorie: 'Hygiène', image: '/uploads/hygiene/magix.jpg' },

      // Épices
      { nom: 'Ras el Hanout 50g', prix: 15.00, description: 'Mélange d\'épices marocain.', categorie: 'Épices', image: '/uploads/epices/ras_hanout.jpg' },
      { nom: 'Kamoun (Cumin) 50g', prix: 10.00, description: 'Cumin moulu pur.', categorie: 'Épices', image: '/uploads/epices/cumin.jpg' }
    ];

    // Clear existing products to avoid duplicates or keep them? 
    // The user said "Remplacer", so I'll clear first.
    await Product.destroy({ where: {} });
    console.log('Anciens produits supprimés.');

    for (const store of stores) {
      for (const pData of productsData) {
        const category = categories.find(c => c.nom === pData.categorie);
        await Product.create({
          nom: pData.nom,
          prix: pData.prix,
          description: pData.description,
          categorie_id: category.id,
          epicier_id: store.id,
          image_principale: pData.image
        });
      }
    }

    console.log(`Données du marché marocain injectées avec succès pour ${stores.length} boutiques ! 🇲🇦🥛🥨`);
    process.exit(0);
  } catch (error) {
    console.error('Erreur lors du seeding des produits:', error);
    process.exit(1);
  }
};

seedProducts();
