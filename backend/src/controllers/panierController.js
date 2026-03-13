const Product = require('../models/Product');
const EpicierProduct = require('../models/EpicierProduct');
const { Op } = require('sequelize');
const cartStore = require('../store/cartStore');

const panierController = {
  getPanier: async (req, res) => {
    try {
      const clientId = req.user.id;
      const items = cartStore.getItems(clientId);
      if (items.length === 0) {
        return res.status(200).json({ panier_id: null, articles: [], total: 0 });
      }
      const productIds = [...new Set(items.map((i) => i.produit_id))];
      const products = await Product.findAll({
        where: { id: { [Op.in]: productIds } },
        attributes: ['id', 'nom', 'image_principale'],
      });
      const productMap = {};
      products.forEach((p) => { productMap[p.id] = p; });
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
        const prod = productMap[row.produit_id];
        const ligneTotal = prix * (row.quantite || 0);
        totalProduits += ligneTotal;
        return {
          produit_id: row.produit_id,
          quantite: row.quantite,
          nom: prod?.nom,
          prix,
          image_principale: prod?.image_principale,
          epicier_id: epicierId,
        };
      });
      res.status(200).json({
        panier_id: null,
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
      const quantiteFinale = cartStore.addItem(clientId, produit_id, quantite, epicier_id);
      res.status(200).json({ message: 'Article ajouté', quantite: quantiteFinale });
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
      const qty = cartStore.updateQuantity(clientId, produitId, quantite);
      if (qty === null) {
        return res.status(404).json({ message: 'Article non trouvé dans le panier' });
      }
      res.status(200).json({ message: qty === 0 ? 'Article retiré' : 'Quantité mise à jour', quantite: qty });
    } catch (error) {
      console.error('Erreur updateQuantity:', error);
      res.status(500).json({ message: 'Erreur lors de la mise à jour', error: error.message });
    }
  },

  removeItem: async (req, res) => {
    try {
      const clientId = req.user.id;
      const { produitId } = req.params;
      const itemsBefore = cartStore.getItems(clientId).length;
      cartStore.removeItem(clientId, produitId);
      const itemsAfter = cartStore.getItems(clientId).length;
      if (itemsBefore === itemsAfter) {
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
