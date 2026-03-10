const express = require('express');
const router = express.Router();
const Product = require('../models/Product');
const { Sequelize } = require('../config/db');

// Récupérer les produits d'un épicier pour une catégorie donnée
router.get('/store/:storeId/category/:categoryId', async (req, res) => {
  try {
    const { storeId, categoryId } = req.params;
    
    const products = await Product.findAll({
      where: {
        epicier_id: storeId,
        categorie_id: categoryId
      },
      order: [['nom', 'ASC']]
    });

    res.json(products);
  } catch (error) {
    console.error('Erreur fetch products by category:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// Rechercher des produits chez un épicier
router.get('/store/:storeId/search', async (req, res) => {
  try {
    const { storeId } = req.params;
    const { q } = req.query;

    if (!q) return res.json([]);

    const products = await Product.findAll({
      where: {
        epicier_id: storeId,
        nom: {
          [Sequelize.Op.like]: `%${q}%`
        }
      },
      limit: 20
    });

    res.json(products);
  } catch (error) {
    console.error('Erreur search products:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

module.exports = router;
