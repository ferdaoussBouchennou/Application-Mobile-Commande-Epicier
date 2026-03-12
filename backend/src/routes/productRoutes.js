const express = require('express');
const router = express.Router();
const Product = require('../models/Product');
const EpicierProduct = require('../models/EpicierProduct');
const { Sequelize } = require('../config/db');

// Récupérer les produits d'un épicier pour une catégorie donnée (catalogue client)
router.get('/store/:storeId/category/:categoryId', async (req, res) => {
  try {
    const { storeId, categoryId } = req.params;

    const linkList = await EpicierProduct.findAll({
      where: { epicier_id: storeId, is_active: true },
      include: [{ model: Product, as: 'produit', where: { categorie_id: categoryId } }],
      order: [[{ model: Product, as: 'produit' }, 'nom', 'ASC']],
    });

    const products = linkList.filter((ep) => ep.produit).map((ep) => ({
      id: ep.produit.id,
      nom: ep.produit.nom,
      prix: parseFloat(ep.prix),
      description: ep.produit.description,
      epicier_id: ep.epicier_id,
      categorie_id: ep.produit.categorie_id,
      image_principale: ep.produit.image_principale,
    }));
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

    const linkList = await EpicierProduct.findAll({
      where: { epicier_id: storeId, is_active: true },
      include: [{ model: Product, as: 'produit', where: { nom: { [Sequelize.Op.like]: `%${q}%` } } }],
      limit: 20,
    });

    const products = linkList.filter((ep) => ep.produit).map((ep) => ({
      id: ep.produit.id,
      nom: ep.produit.nom,
      prix: parseFloat(ep.prix),
      description: ep.produit.description,
      epicier_id: ep.epicier_id,
      categorie_id: ep.produit.categorie_id,
      image_principale: ep.produit.image_principale,
    }));
    res.json(products);
  } catch (error) {
    console.error('Erreur search products:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

module.exports = router;
