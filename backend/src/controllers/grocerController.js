const path = require('path');
const fs = require('fs');
const sequelize = require('../config/db');
const { QueryTypes } = require('sequelize');
const { Op } = require('sequelize');
const Product = require('../models/Product');
const Category = require('../models/Category');
const EpicierProduct = require('../models/EpicierProduct');

/** Sanitise une chaîne pour en faire un nom de dossier ou de fichier (sans espaces ni caractères spéciaux). */
function sanitizeName(str) {
  if (!str || typeof str !== 'string') return '';
  return str
    .normalize('NFD')
    .replace(/\p{Diacritic}/gu, '')
    .replace(/[\s]+/g, '_')
    .replace(/[^a-zA-Z0-9_-]/g, '')
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '')
    .slice(0, 80) || 'image';
}

/**
 * Si l'image du produit a un nom générique (image, image-1, ...), renomme le fichier
 * avec le nom du produit en base et met à jour image_principale.
 * @param {Object} product - Instance Sequelize Product avec nom, image_principale
 * @returns {Promise<string|null>} Nouveau chemin ou null si pas de changement
 */
async function renameImageToProductName(product) {
  const img = product.image_principale;
  if (!img || typeof img !== 'string' || !img.startsWith('uploads/')) return null;
  const base = path.basename(img);
  const ext = path.extname(base);
  const nameWithoutExt = base.slice(0, -ext.length);
  const isGeneric = nameWithoutExt === 'image' || /^image-\d+$/.test(nameWithoutExt) || nameWithoutExt.startsWith('temp_');
  if (!isGeneric) return null;
  const fullPath = path.join(__dirname, '..', '..', img.replace(/\//g, path.sep));
  if (!fs.existsSync(fullPath)) return null;
  const dir = path.dirname(fullPath);
  const folderName = path.basename(dir);
  const baseName = sanitizeName(product.nom) || 'produit';
  let newFilename = `${baseName}${ext}`;
  let newPath = path.join(dir, newFilename);
  if (newPath === fullPath) return img;
  if (fs.existsSync(newPath)) {
    fs.unlinkSync(newPath);
  }
  fs.renameSync(fullPath, newPath);
  const newRelative = path.join('uploads', folderName, newFilename).replace(/\\/g, '/');
  product.image_principale = newRelative;
  await product.save();
  return newRelative;
}

/** Construit un objet catalogue (produit + lien épicier) pour les réponses API. */
function toCatalogueItem(epicierProduct, product) {
  const p = product || epicierProduct.produit;
  return {
    id: p.id,
    nom: p.nom,
    prix: parseFloat(epicierProduct.prix),
    description: p.description,
    epicier_id: epicierProduct.epicier_id,
    categorie_id: p.categorie_id,
    categorie_nom: p.categorie?.nom ?? null,
    image_principale: p.image_principale,
  };
}

const grocerController = {
  // Liste des produits du catalogue de l'épicier connecté (optionnel: filtre par categorie_id)
  getMyProducts: async (req, res) => {
    try {
      const epicierId = req.user.storeId;
      if (!epicierId) {
        return res.status(403).json({ message: 'Store ID manquant' });
      }
      const categorieId = req.query.categorie_id ? parseInt(req.query.categorie_id, 10) : null;
      const where = { epicier_id: epicierId, is_active: true };
      const epInclude = [{ model: Product, as: 'produit', include: [{ model: Category, as: 'categorie', attributes: ['id', 'nom'] }] }];
      const linkList = await EpicierProduct.findAll({
        where,
        include: epInclude,
        order: [[{ model: Product, as: 'produit' }, 'nom', 'ASC']],
      });
      const list = linkList.map((ep) => toCatalogueItem(ep));
      res.status(200).json(list);
    } catch (error) {
      console.error('Erreur getMyProducts:', error);
      res.status(500).json({ message: 'Erreur lors de la récupération du catalogue', error: error.message });
    }
  },

  createProduct: async (req, res) => {
    try {
      const epicierId = req.user.storeId;
      if (!epicierId) {
        return res.status(403).json({ message: 'Store ID manquant' });
      }
      const { nom, prix, description, categorie_id, image_principale } = req.body;
      if (!nom || prix == null || !categorie_id) {
        return res.status(400).json({ message: 'Nom, prix et catégorie sont requis.' });
      }
      const [product] = await Product.findOrCreate({
        where: { nom: nom.trim(), categorie_id: parseInt(categorie_id, 10) },
        defaults: {
          nom: nom.trim(),
          description: description?.trim() || null,
          categorie_id: parseInt(categorie_id, 10),
          image_principale: image_principale?.trim() || null,
        },
      });
      await renameImageToProductName(product);
      const [epicierProduct, created] = await EpicierProduct.findOrCreate({
        where: { epicier_id: epicierId, produit_id: product.id },
        defaults: { epicier_id: epicierId, produit_id: product.id, prix: parseFloat(prix), is_active: true },
      });
      if (!created) {
        epicierProduct.prix = parseFloat(prix);
        epicierProduct.is_active = true;
        await epicierProduct.save();
      }
      const withCategory = await Product.findByPk(product.id, {
        include: [{ model: Category, as: 'categorie', attributes: ['id', 'nom'] }],
      });
      res.status(201).json({
        id: withCategory.id,
        nom: withCategory.nom,
        prix: parseFloat(epicierProduct.prix),
        description: withCategory.description,
        epicier_id: epicierId,
        categorie_id: withCategory.categorie_id,
        categorie_nom: withCategory.categorie?.nom ?? null,
        image_principale: withCategory.image_principale,
      });
    } catch (error) {
      console.error('Erreur createProduct:', error);
      res.status(500).json({ message: 'Erreur lors de la création du produit', error: error.message });
    }
  },

  updateProduct: async (req, res) => {
    try {
      const epicierId = req.user.storeId;
      if (!epicierId) {
        return res.status(403).json({ message: 'Store ID manquant' });
      }
      const produitId = parseInt(req.params.id, 10);
      const epicierProduct = await EpicierProduct.findOne({
        where: { epicier_id: epicierId, produit_id: produitId, is_active: true },
        include: [{ model: Product, as: 'produit', include: [{ model: Category, as: 'categorie', attributes: ['id', 'nom'] }] }],
      });
      if (!epicierProduct || !epicierProduct.produit) {
        return res.status(404).json({ message: 'Produit introuvable.' });
      }
      const product = epicierProduct.produit;
      const { nom, prix, description, categorie_id, image_principale } = req.body;
      if (nom != null) product.nom = nom.trim();
      if (description !== undefined) product.description = description?.trim() || null;
      if (categorie_id != null) product.categorie_id = parseInt(categorie_id, 10);
      if (image_principale !== undefined) product.image_principale = image_principale?.trim() || null;
      if (prix != null) epicierProduct.prix = parseFloat(prix);
      await product.save();
      await epicierProduct.save();
      await renameImageToProductName(product);
      res.status(200).json(toCatalogueItem(epicierProduct));
    } catch (error) {
      console.error('Erreur updateProduct:', error);
      res.status(500).json({ message: 'Erreur lors de la mise à jour du produit', error: error.message });
    }
  },

  // Upload d'une image produit : dossier = nom de la catégorie, fichier = nom du produit
  uploadProductImage: async (req, res) => {
    try {
      if (!req.file || !req.file.buffer) {
        return res.status(400).json({ message: 'Aucun fichier image envoyé.' });
      }
      const categorieId = req.body.categorie_id;
      if (!categorieId) {
        return res.status(400).json({ message: 'categorie_id est requis.' });
      }
      const category = await Category.findByPk(categorieId);
      if (!category) {
        return res.status(400).json({ message: 'Catégorie introuvable.' });
      }
      const folderName = sanitizeName(category.nom) || 'categorie';
      const dir = path.join(__dirname, '..', '..', 'uploads', folderName);
      fs.mkdirSync(dir, { recursive: true });
      const ext = path.extname(req.file.originalname) || '.jpg';
      const safeExt = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext.toLowerCase()) ? ext : '.jpg';
      const productName = req.body.nom ? String(req.body.nom).trim() : '';
      const baseName = sanitizeName(productName) || `temp_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`;
      let filename = `${baseName}${safeExt}`;
      let filePath = path.join(dir, filename);
      let suffix = 0;
      while (fs.existsSync(filePath)) {
        suffix += 1;
        filename = `${baseName}-${suffix}${safeExt}`;
        filePath = path.join(dir, filename);
      }
      fs.writeFileSync(filePath, req.file.buffer);
      const relativePath = path.join('uploads', folderName, filename).replace(/\\/g, '/');
      res.status(200).json({ image_principale: relativePath });
    } catch (error) {
      console.error('Erreur uploadProductImage:', error);
      res.status(500).json({ message: 'Erreur lors de l\'upload de l\'image', error: error.message });
    }
  },

  // Retirer le produit du catalogue (désactivation), sans suppression en BDD.
  deleteProduct: async (req, res) => {
    try {
      const epicierId = req.user.storeId;
      if (!epicierId) {
        return res.status(403).json({ message: 'Store ID manquant' });
      }
      const produitId = parseInt(req.params.id, 10);
      const [updated] = await EpicierProduct.update(
        { is_active: false },
        { where: { epicier_id: epicierId, produit_id: produitId } }
      );
      if (!updated) {
        return res.status(404).json({ message: 'Produit introuvable.' });
      }
      res.status(200).json({ message: 'Produit retiré du catalogue.' });
    } catch (error) {
      console.error('Erreur deleteProduct:', error);
      res.status(500).json({ message: 'Erreur lors du retrait du produit', error: error.message });
    }
  },

  // Produits disponibles pour la catégorie : autres épiciers (actifs) + mes propres produits retirés (inactifs), pour réajout ou copie.
  getAvailableProductsForCategory: async (req, res) => {
    try {
      const epicierId = req.user.storeId;
      if (!epicierId) {
        return res.status(403).json({ message: 'Store ID manquant' });
      }
      const categoryId = parseInt(req.params.categoryId, 10);
      if (Number.isNaN(categoryId)) {
        return res.status(400).json({ message: 'Identifiant de catégorie invalide.' });
      }
      const myActive = await EpicierProduct.findAll({
        where: { epicier_id: epicierId, is_active: true },
        include: [{ model: Product, as: 'produit', where: { categorie_id: categoryId }, attributes: ['nom'] }],
      });
      const myNoms = myActive.map((ep) => ep.produit?.nom?.trim().toLowerCase()).filter(Boolean);
      const others = await EpicierProduct.findAll({
        where: { epicier_id: { [Op.ne]: epicierId }, is_active: true },
        include: [{ model: Product, as: 'produit', where: { categorie_id: categoryId }, include: [{ model: Category, as: 'categorie', attributes: ['id', 'nom'] }] }],
        order: [[{ model: Product, as: 'produit' }, 'nom', 'ASC']],
      });
      const myRetired = await EpicierProduct.findAll({
        where: { epicier_id: epicierId, is_active: false },
        include: [{ model: Product, as: 'produit', where: { categorie_id: categoryId }, include: [{ model: Category, as: 'categorie', attributes: ['id', 'nom'] }] }],
        order: [[{ model: Product, as: 'produit' }, 'nom', 'ASC']],
      });
      const toItem = (ep, isRetiredMine) => ({
        ...toCatalogueItem(ep),
        is_retired_mine: isRetiredMine,
      });
      const byNom = new Map();
      myRetired.filter((ep) => ep.produit).forEach((ep) => {
        const key = ep.produit.nom.trim().toLowerCase();
        if (!byNom.has(key)) byNom.set(key, toItem(ep, true));
      });
      others
        .filter((ep) => ep.produit && !myNoms.includes(ep.produit.nom.trim().toLowerCase()))
        .forEach((ep) => {
          const key = ep.produit.nom.trim().toLowerCase();
          if (!byNom.has(key)) byNom.set(key, toItem(ep, false));
        });
      const list = Array.from(byNom.values()).sort((a, b) => a.nom.localeCompare(b.nom));
      res.status(200).json(list);
    } catch (error) {
      console.error('Erreur getAvailableProductsForCategory:', error);
      res.status(500).json({ message: 'Erreur lors de la récupération des produits disponibles', error: error.message });
    }
  },

  // Réintégrer au catalogue un produit que l'épicier avait retiré (is_active -> true). Optionnel : mettre à jour le prix.
  restoreProductToCatalogue: async (req, res) => {
    try {
      const epicierId = req.user.storeId;
      if (!epicierId) {
        return res.status(403).json({ message: 'Store ID manquant' });
      }
      const productId = parseInt(req.params.id, 10);
      if (Number.isNaN(productId)) {
        return res.status(400).json({ message: 'Identifiant de produit invalide.' });
      }
      const epicierProduct = await EpicierProduct.findOne({
        where: { epicier_id: epicierId, produit_id: productId },
        include: [{ model: Product, as: 'produit', include: [{ model: Category, as: 'categorie', attributes: ['id', 'nom'] }] }],
      });
      if (!epicierProduct || !epicierProduct.produit) {
        return res.status(404).json({ message: 'Produit introuvable.' });
      }
      const { prix } = req.body || {};
      epicierProduct.is_active = true;
      if (typeof prix === 'number' && !Number.isNaN(prix)) {
        epicierProduct.prix = prix;
      }
      await epicierProduct.save();
      res.status(200).json(toCatalogueItem(epicierProduct));
    } catch (error) {
      console.error('Erreur restoreProductToCatalogue:', error);
      res.status(500).json({ message: 'Erreur lors de la réintégration du produit', error: error.message });
    }
  },

  // Copier un produit existant (d'un autre épicier) dans le catalogue de l'épicier connecté.
  copyProductToCatalogue: async (req, res) => {
    try {
      const epicierId = req.user.storeId;
      if (!epicierId) {
        return res.status(403).json({ message: 'Store ID manquant' });
      }
      const sourceProductId = parseInt(req.params.productId, 10);
      if (Number.isNaN(sourceProductId)) {
        return res.status(400).json({ message: 'Identifiant de produit invalide.' });
      }
      const sourceProduct = await Product.findByPk(sourceProductId, {
        include: [{ model: Category, as: 'categorie', attributes: ['id', 'nom'] }],
      });
      if (!sourceProduct) {
        return res.status(404).json({ message: 'Produit source introuvable.' });
      }
      const existingLink = await EpicierProduct.findOne({ where: { epicier_id: epicierId, produit_id: sourceProductId } });
      if (existingLink) {
        return res.status(400).json({ message: 'Ce produit appartient déjà à votre catalogue.' });
      }
      const sourceLink = await EpicierProduct.findOne({ where: { produit_id: sourceProductId } });
      const prixSource = sourceLink ? parseFloat(sourceLink.prix) : 0;
      const { prix } = req.body || {};
      const epicierProduct = await EpicierProduct.create({
        epicier_id: epicierId,
        produit_id: sourceProduct.id,
        prix: typeof prix === 'number' && !Number.isNaN(prix) ? prix : prixSource,
        is_active: true,
      });
      res.status(201).json({
        id: sourceProduct.id,
        nom: sourceProduct.nom,
        prix: parseFloat(epicierProduct.prix),
        description: sourceProduct.description,
        epicier_id: epicierId,
        categorie_id: sourceProduct.categorie_id,
        categorie_nom: sourceProduct.categorie?.nom ?? null,
        image_principale: sourceProduct.image_principale,
      });
    } catch (error) {
      console.error('Erreur copyProductToCatalogue:', error);
      res.status(500).json({ message: 'Erreur lors de l\'ajout du produit au catalogue', error: error.message });
    }
  },

  // Produits inactifs de l'épicier dans une catégorie (pour restauration avec sélection multiple).
  getInactiveProductsForCategory: async (req, res) => {
    try {
      const epicierId = req.user.storeId;
      if (!epicierId) {
        return res.status(403).json({ message: 'Store ID manquant' });
      }
      const categoryId = parseInt(req.params.categoryId, 10);
      if (Number.isNaN(categoryId)) {
        return res.status(400).json({ message: 'Identifiant de catégorie invalide.' });
      }
      const linkList = await EpicierProduct.findAll({
        where: { epicier_id: epicierId, is_active: false },
        include: [{ model: Product, as: 'produit', where: { categorie_id: categoryId }, include: [{ model: Category, as: 'categorie', attributes: ['id', 'nom'] }] }],
        order: [[{ model: Product, as: 'produit' }, 'nom', 'ASC']],
      });
      const list = linkList.filter((ep) => ep.produit).map((ep) => toCatalogueItem(ep));
      res.status(200).json(list);
    } catch (error) {
      console.error('Erreur getInactiveProductsForCategory:', error);
      res.status(500).json({ message: 'Erreur lors de la récupération des produits inactifs', error: error.message });
    }
  },

  // Restaurer une catégorie : réactiver plusieurs produits en une fois (sélection multiple).
  restoreCategoryWithProducts: async (req, res) => {
    try {
      const epicierId = req.user.storeId;
      if (!epicierId) {
        return res.status(403).json({ message: 'Store ID manquant' });
      }
      const categoryId = parseInt(req.params.categoryId, 10);
      if (Number.isNaN(categoryId)) {
        return res.status(400).json({ message: 'Identifiant de catégorie invalide.' });
      }
      const productIds = req.body.product_ids;
      if (!Array.isArray(productIds) || productIds.length === 0) {
        return res.status(400).json({ message: 'Sélectionnez au moins un produit (product_ids).' });
      }
      const ids = productIds.map((id) => parseInt(id, 10)).filter((id) => !Number.isNaN(id));
      const [updatedCount] = await EpicierProduct.update(
        { is_active: true },
        { where: { epicier_id: epicierId, produit_id: ids, is_active: false } }
      );
      res.status(200).json({
        message: 'Catégorie restaurée avec les produits sélectionnés.',
        restoredCount: updatedCount,
      });
    } catch (error) {
      console.error('Erreur restoreCategoryWithProducts:', error);
      res.status(500).json({ message: 'Erreur lors de la restauration', error: error.message });
    }
  },

  // Retirer une catégorie du catalogue épicier : désactive tous les produits (is_active = false). La catégorie n'est pas supprimée en BDD.
  removeCategoryFromCatalogue: async (req, res) => {
    try {
      const epicierId = req.user.storeId;
      if (!epicierId) {
        return res.status(403).json({ message: 'Store ID manquant' });
      }
      const categoryId = parseInt(req.params.categoryId, 10);
      if (Number.isNaN(categoryId)) {
        return res.status(400).json({ message: 'Identifiant de catégorie invalide.' });
      }
      const productIds = await Product.findAll({ where: { categorie_id: categoryId }, attributes: ['id'] }).then((rows) => rows.map((r) => r.id));
      const [updatedCount] = productIds.length
        ? await EpicierProduct.update({ is_active: false }, { where: { epicier_id: epicierId, produit_id: productIds } })
        : [0];
      res.status(200).json({
        message: 'Catégorie retirée du catalogue.',
        deletedCount: updatedCount,
      });
    } catch (error) {
      console.error('Erreur removeCategoryFromCatalogue:', error);
      res.status(500).json({ message: 'Erreur lors du retrait de la catégorie', error: error.message });
    }
  },

  getDashboard: async (req, res) => {
    try {
      const epicierId = req.user.storeId;
      if (!epicierId) {
        return res.status(403).json({ message: 'Store ID manquant' });
      }

      const periodDays = 30;

      const kpiRows = await sequelize.query(
        `SELECT
          (SELECT COUNT(*) FROM commandes WHERE epicier_id = :epicierId AND date_commande >= DATE_SUB(CURDATE(), INTERVAL :periodDays DAY)) AS total_commandes,
          (SELECT COALESCE(SUM(montant_total), 0) FROM commandes WHERE epicier_id = :epicierId AND date_commande >= DATE_SUB(CURDATE(), INTERVAL :periodDays DAY)) AS ca_total,
          (SELECT COALESCE(AVG(note), 0) FROM avis WHERE epicier_id = :epicierId) AS note_moyenne`,
        { replacements: { epicierId, periodDays }, type: QueryTypes.SELECT }
      );
      const kpis = Array.isArray(kpiRows) && kpiRows.length > 0 ? kpiRows[0] : {};

      const commandesParJour = await sequelize.query(
        `SELECT DATE(date_commande) AS jour, COUNT(*) AS nb
         FROM commandes
         WHERE epicier_id = :epicierId AND date_commande >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
         GROUP BY DATE(date_commande)
         ORDER BY jour`,
        { replacements: { epicierId }, type: QueryTypes.SELECT }
      );

      const topProduits = await sequelize.query(
        `SELECT p.id, p.nom, SUM(d.quantite) AS total_quantite
         FROM detailscommande d
         INNER JOIN commandes c ON c.id = d.commande_id AND c.epicier_id = :epicierId
         INNER JOIN produits p ON p.id = d.produit_id
         WHERE c.date_commande >= DATE_SUB(CURDATE(), INTERVAL :periodDays DAY)
         GROUP BY p.id, p.nom
         ORDER BY total_quantite DESC
         LIMIT 5`,
        { replacements: { epicierId, periodDays }, type: QueryTypes.SELECT }
      );

      const totalQuantite = topProduits.reduce((acc, row) => acc + Number(row.total_quantite), 0);

      const topProductsWithPct = topProduits.map((row) => ({
        id: row.id,
        nom: row.nom,
        quantite: Number(row.total_quantite),
        percentage: totalQuantite > 0 ? Math.round((Number(row.total_quantite) / totalQuantite) * 100) : 0,
      }));

      const joursLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
      const last7Days = [];
      for (let i = 6; i >= 0; i--) {
        const d = new Date();
        d.setDate(d.getDate() - i);
        const dateStr = d.toISOString().slice(0, 10);
        const found = commandesParJour.find((r) => r.jour && String(r.jour).slice(0, 10) === dateStr);
        last7Days.push({
          jour: dateStr,
          label: joursLabels[6 - i],
          nb: found ? Number(found.nb) : 0,
        });
      }

      res.status(200).json({
        kpis: {
          totalCommandes: Number(kpis?.total_commandes ?? 0),
          caTotal: Number(kpis?.ca_total ?? 0),
          noteMoyenne: Number(Number(kpis?.note_moyenne ?? 0).toFixed(1)),
          annulations: 0,
        },
        chartData: last7Days,
        topProducts: topProductsWithPct,
      });
    } catch (error) {
      console.error('Erreur getDashboard:', error);
      res.status(500).json({ message: 'Erreur lors de la récupération du tableau de bord', error: error.message });
    }
  },
};

module.exports = grocerController;
