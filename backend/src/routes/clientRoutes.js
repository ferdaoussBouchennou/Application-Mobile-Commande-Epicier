const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Store = require('../models/Store');
const Category = require('../models/Category');
const Product = require('../models/Product');
const { Op } = require('sequelize');

// Route pour récupérer les catégories d'un épicier spécifique (uniquement si statut_inscription = COMPLETE)
router.get('/stores/:storeId/categories', async (req, res) => {
  try {
    const { storeId } = req.params;
    const store = await Store.findByPk(storeId);
    if (!store || !store.is_active || store.statut_inscription !== 'COMPLETE') {
      return res.status(404).json({ error: 'Épicier introuvable' });
    }
    
    // On cherche les catégories qui ont des produits ACTIFS liés à cet épicier
    const products = await Product.findAll({
      where: { 
        epicier_id: storeId,
        is_active: true 
      },
      attributes: ['categorie_id'],
      group: ['categorie_id']
    });

    const categoryIds = products.map(p => p.categorie_id);
    
    const categories = await Category.findAll({
      where: {
        id: { [Op.in]: categoryIds }
      }
    });

    res.json(categories);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
