const express = require('express');
const router = express.Router();
const Category = require('../models/Category');
const Product = require('../models/Product');
const { Sequelize } = require('../config/db');

// Récupérer toutes les catégories avec le nombre de produits pour un épicier donné (avec pagination)
router.get('/store/:storeId', async (req, res) => {
  try {
    const { storeId } = req.params;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;
    
    // On récupère toutes les catégories qui ont au moins un produit pour cet épicier
    const allCategories = await Category.findAll({
      attributes: [
        'id',
        'nom',
        [
          Sequelize.literal(`(
            SELECT COUNT(*)
            FROM produits AS p
            WHERE p.categorie_id = Category.id
            AND p.epicier_id = ${storeId}
          )`),
          'productCount'
        ]
      ],
      having: Sequelize.literal('productCount > 0')
    });

    const totalItems = allCategories.length;
    const paginatedCategories = allCategories.slice(offset, offset + limit);

    res.json({
      totalItems,
      totalPages: Math.ceil(totalItems / limit),
      currentPage: page,
      categories: paginatedCategories
    });
  } catch (error) {
    console.error('Erreur categories store:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

module.exports = router;
