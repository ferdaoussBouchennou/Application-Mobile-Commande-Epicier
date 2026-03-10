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

    // 3. Create Products (Staples based on UI categories)
    const productsData = [
      {
        nom: 'Huile d\'olive Vierge',
        prix: 45.00,
        description: 'Bouteille de 1 Litre d\'huile d\'olive extra vierge.',
        categorie: 'Huiles',
        image: 'uploads/huile_olive.jpg'
      },
      {
        nom: 'Huile de Tournesol',
        prix: 18.00,
        description: 'Huile de tournesol pure pour cuisson.',
        categorie: 'Huiles',
        image: 'uploads/huile_tournesol.jpg'
      },
      {
        nom: 'Lait Central 1L',
        prix: 7.00,
        description: 'Lait frais entier conditionné en carton.',
        categorie: 'Laitiers',
        image: 'uploads/lait_central.jpg'
      },
      {
        nom: 'Yaourt Nature',
        prix: 2.50,
        description: 'Yaourt crémeux nature.',
        categorie: 'Laitiers',
        image: 'uploads/yaourt.jpg'
      },
      {
        nom: 'Farine de blé 1kg',
        prix: 12.00,
        description: 'Farine de qualité supérieure pour pâtisserie et pain.',
        categorie: 'Farines',
        image: 'uploads/farine.jpg'
      },
      {
        nom: 'Semoule Fine 1kg',
        prix: 14.00,
        description: 'Semoule de blé dur de qualité supérieure.',
        categorie: 'Farines',
        image: 'uploads/semoule.jpg'
      },
      {
        nom: 'Pain de Mie',
        prix: 15.00,
        description: 'Grand pain de mie tranché.',
        categorie: 'Boulangerie',
        image: 'uploads/pain_mie.jpg'
      },
      {
        nom: 'Baguette Tradition',
        prix: 2.00,
        description: 'Pain artisanal croustillant.',
        categorie: 'Boulangerie',
        image: 'uploads/baguette.jpg'
      },
      {
        nom: 'Thon à l\'huile 160g',
        prix: 16.00,
        description: 'Morceaux de thon à l\'huile végétale.',
        categorie: 'Conserves',
        image: 'uploads/thon.jpg'
      },
      {
        nom: 'Tomate Concentrée 400g',
        prix: 10.00,
        description: 'Double concentré de tomate.',
        categorie: 'Conserves',
        image: 'uploads/tomate.jpg'
      },
      {
        nom: 'Chocolat Noir 100g',
        prix: 12.00,
        description: 'Chocolat noir 70% cacao.',
        categorie: 'Confiserie',
        image: 'uploads/chocolat.jpg'
      },
      {
        nom: 'Eau Minérale 1.5L',
        prix: 6.00,
        description: 'Eau minérale naturelle pure.',
        categorie: 'Boissons',
        image: 'uploads/eau.jpg'
      },
      {
        nom: 'Savon liquide 500ml',
        prix: 25.00,
        description: 'Savon antibactérien pour les mains.',
        categorie: 'Hygiène',
        image: 'uploads/savon.jpg'
      },
      {
        nom: 'Poivre Noir 50g',
        prix: 8.00,
        description: 'Poivre noir moulu aromatique.',
        categorie: 'Épices',
        image: 'uploads/poivre.jpg'
      }
    ];

    for (const store of stores) {
      for (const pData of productsData) {
        const category = categories.find(c => c.nom === pData.categorie);
        await Product.findOrCreate({
          where: { 
            nom: pData.nom,
            epicier_id: store.id
          },
          defaults: {
            prix: pData.prix,
            description: pData.description,
            categorie_id: category.id,
            image_principale: pData.image
          }
        });
      }
    }

    console.log(`Produits alignés avec le design ajoutés pour ${stores.length} boutiques successfully! 🥫🥛🧴`);
    process.exit(0);
  } catch (error) {
    console.error('Erreur lors du seeding des produits:', error);
    process.exit(1);
  }
};

seedProducts();
