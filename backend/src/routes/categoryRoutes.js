const express = require('express');
const router = express.Router();
const Category = require('../models/Category');
const Product = require('../models/Product');
const { Sequelize } = require('../config/db');
const { authMiddleware, requireEpicierOrAdmin } = require('../middlewares/auth');

// Liste de toutes les catégories (pour formulaire épicier, dropdown, choix "catégorie existante")
router.get('/', async (req, res) => {
  try {
    const categories = await Category.findAll({ order: [['nom', 'ASC']] });
    res.json(categories);
  } catch (error) {
    console.error('Erreur list categories:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// Créer une nouvelle catégorie (épicier ou admin)
router.post('/', authMiddleware, requireEpicierOrAdmin, async (req, res) => {
  try {
    const { nom } = req.body;
    if (!nom || typeof nom !== 'string' || !nom.trim()) {
      return res.status(400).json({ message: 'Le nom de la catégorie est requis.' });
    }
    const category = await Category.create({ nom: nom.trim() });
    res.status(201).json({ id: category.id, nom: category.nom });
  } catch (error) {
    console.error('Erreur create category:', error);
    res.status(500).json({ message: 'Erreur serveur' });
  }
});

// Récupérer toutes les catégories avec le nombre de produits pour un épicier donné (avec pagination)
router.get('/store/:storeId', async (req, res) => {
  try {
    const storeIdInt = parseInt(req.params.storeId, 10);
    if (Number.isNaN(storeIdInt)) {
      return res.status(400).json({ message: 'Identifiant de magasin invalide.' });
    }
    const { q } = req.query;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const includeRetired = req.query.includeRetired === 'true';
    const offset = (page - 1) * limit;

    const whereClause = {
      nom: { [Sequelize.Op.like]: `%${q || ''}%` }
    };

    // Catégories qui ont au moins un produit (actif ou inactif) pour cet épicier
    const allCategories = await Category.findAll({
      where: q ? whereClause : {},
      attributes: [
        'id',
        'nom',
        [
          Sequelize.literal(`(
            SELECT COUNT(*) FROM produits AS p
            WHERE p.categorie_id = Category.id AND p.epicier_id = ${storeIdInt}
            AND (p.is_active = 1 OR p.is_active IS NULL)
          )`),
          'productCount'
        ],
        [
          Sequelize.literal(`(
            SELECT COUNT(*) FROM produits AS p
            WHERE p.categorie_id = Category.id AND p.epicier_id = ${storeIdInt}
            AND p.is_active = 0
          )`),
          'retiredCount'
        ]
      ],
      having: includeRetired 
        ? Sequelize.literal('(productCount + retiredCount) > 0')
        : Sequelize.literal('productCount > 0')
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
