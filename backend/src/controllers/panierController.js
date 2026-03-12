const Panier = require('../models/Panier');
const PanierProduit = require('../models/PanierProduit');
const Product = require('../models/Product');
const EpicierProduct = require('../models/EpicierProduct');
const { Op } = require('sequelize');

const getOrCreatePanier = async (clientId) => {
  const [panier] = await Panier.findOrCreate({
    where: { client_id: clientId },
    defaults: { date_creation: new Date().toISOString().slice(0, 10) },
  });
  return panier;
};

const panierController = {
  getPanier: async (req, res) => {
    try {
      const clientId = req.user.id;
      const panier = await getOrCreatePanier(clientId);
      const items = await PanierProduit.findAll({
        where: { panier_id: panier.id },
        include: [{ model: Product, as: 'Product', attributes: ['id', 'nom', 'image_principale'] }],
      });
      if (items.length === 0) {
        return res.status(200).json({ panier_id: panier.id, articles: [], total: 0 });
      }
      const keysWithEpicier = items.filter((i) => i.epicier_id != null).map((i) => ({ epicier_id: i.epicier_id, produit_id: i.produit_id }));
      const produitIdsNull = [...new Set(items.filter((i) => i.epicier_id == null).map((i) => i.produit_id))];
      const epMap = {};
      if (keysWithEpicier.length > 0) {
        const eps = await EpicierProduct.findAll({
          where: { [Op.or]: keysWithEpicier.map((k) => ({ epicier_id: k.epicier_id, produit_id: k.produit_id })) },
          attributes: ['epicier_id', 'produit_id', 'prix'],
        });
        eps.forEach((ep) => { epMap[`${ep.epicier_id},${ep.produit_id}`] = ep; });
      }
      const epByProduit = {};
      if (produitIdsNull.length > 0) {
        const eps = await EpicierProduct.findAll({
          where: { produit_id: { [Op.in]: produitIdsNull }, is_active: true },
          attributes: ['epicier_id', 'produit_id', 'prix'],
        });
        eps.forEach((ep) => { if (!epByProduit[ep.produit_id]) epByProduit[ep.produit_id] = ep; });
      }
      let totalProduits = 0;
      const lignes = items.map((row) => {
        let prix = 0;
        let epicierId = row.epicier_id;
        const key = row.epicier_id != null ? `${row.epicier_id},${row.produit_id}` : null;
        if (key && epMap[key]) {
          prix = parseFloat(epMap[key].prix ?? 0);
          epicierId = epMap[key].epicier_id;
        } else if (row.epicier_id == null && epByProduit[row.produit_id]) {
          const ep = epByProduit[row.produit_id];
          prix = parseFloat(ep.prix ?? 0);
          epicierId = ep.epicier_id;
        }
        const ligneTotal = prix * (row.quantite || 0);
        totalProduits += ligneTotal;
        return {
          produit_id: row.produit_id,
          quantite: row.quantite,
          nom: row.Product?.nom,
          prix,
          image_principale: row.Product?.image_principale,
          epicier_id: epicierId,
        };
      });
      res.status(200).json({
        panier_id: panier.id,
        articles: lignes,
        total: Math.round(totalProduits * 100) / 100,
      });
    } catch (error) {
      console.error('Erreur getPanier:', error);
      res.status(500).json({ message: 'Erreur lors de la récupération du panier', error: error.message });
    }
  },

  addItem: async (req, res) => {
    try {
      const clientId = req.user.id;
      const { produit_id, quantite = 1, epicier_id } = req.body;
      if (!produit_id) {
        return res.status(400).json({ message: 'produit_id requis' });
      }
      const panier = await getOrCreatePanier(clientId);
      const [item, created] = await PanierProduit.findOrCreate({
        where: { panier_id: panier.id, produit_id },
        defaults: { quantite: Math.max(1, parseInt(quantite, 10) || 1), epicier_id: epicier_id || null },
      });
      if (!created) {
        item.quantite += Math.max(0, parseInt(quantite, 10) || 1);
        if (epicier_id != null) item.epicier_id = epicier_id;
        await item.save();
      }
      res.status(200).json({ message: 'Article ajouté', quantite: item.quantite });
    } catch (error) {
      console.error('Erreur addItem:', error);
      res.status(500).json({ message: 'Erreur lors de l\'ajout au panier', error: error.message });
    }
  },

  updateQuantity: async (req, res) => {
    try {
      const clientId = req.user.id;
      const { produitId } = req.params;
      const { quantite } = req.body;
      const qty = parseInt(quantite, 10);
      if (isNaN(qty) || qty < 0) {
        return res.status(400).json({ message: 'quantite invalide' });
      }
      const panier = await getOrCreatePanier(clientId);
      const item = await PanierProduit.findOne({
        where: { panier_id: panier.id, produit_id: produitId },
      });
      if (!item) {
        return res.status(404).json({ message: 'Article non trouvé dans le panier' });
      }
      if (qty === 0) {
        await item.destroy();
        return res.status(200).json({ message: 'Article retiré', quantite: 0 });
      }
      item.quantite = qty;
      await item.save();
      res.status(200).json({ message: 'Quantité mise à jour', quantite: item.quantite });
    } catch (error) {
      console.error('Erreur updateQuantity:', error);
      res.status(500).json({ message: 'Erreur lors de la mise à jour', error: error.message });
    }
  },

  removeItem: async (req, res) => {
    try {
      const clientId = req.user.id;
      const { produitId } = req.params;
      const panier = await getOrCreatePanier(clientId);
      const deleted = await PanierProduit.destroy({
        where: { panier_id: panier.id, produit_id: produitId },
      });
      if (!deleted) {
        return res.status(404).json({ message: 'Article non trouvé dans le panier' });
      }
      res.status(200).json({ message: 'Article retiré du panier' });
    } catch (error) {
      console.error('Erreur removeItem:', error);
      res.status(500).json({ message: 'Erreur lors de la suppression', error: error.message });
    }
  },
};

module.exports = panierController;
