const sequelize = require('../config/db');
const { QueryTypes, Op } = require('sequelize');
const Commande = require('../models/Commande');
const DetailCommande = require('../models/DetailCommande');
const Product = require('../models/Product');
const EpicierProduct = require('../models/EpicierProduct');
const Store = require('../models/Store');
const cartStore = require('../store/cartStore');

const commandeController = {
  getMyCommandes: async (req, res) => {
    try {
      const clientId = req.user.id;
      const { statut: statutFilter, epicier_id: epicierFilter } = req.query;
      const where = { client_id: clientId };
      if (statutFilter && ['reçue', 'prête', 'livrée'].includes(statutFilter)) {
        where.statut = statutFilter;
      }
      if (epicierFilter) {
        where.epicier_id = Number(epicierFilter);
      }
      const commandes = await Commande.findAll({
        where,
        include: [{ model: Store, as: 'store', attributes: ['id', 'nom_boutique'] }],
        order: [['date_commande', 'DESC']],
      });
      const ids = commandes.map((c) => c.id);
      const countMap = {};
      if (ids.length > 0) {
        const rows = await sequelize.query(
          `SELECT commande_id, SUM(quantite) AS total FROM detailsCommande WHERE commande_id IN (${ids.join(',')}) GROUP BY commande_id`,
          { type: QueryTypes.SELECT }
        );
        rows.forEach((r) => { countMap[r.commande_id] = Number(r.total ?? 0); });
      }
      const mois = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
      const result = commandes.map((c) => {
        let creneau = '';
        if (c.date_recuperation) {
          const d = new Date(c.date_recuperation);
          const h = d.getHours();
          const m = d.getMinutes();
          creneau = `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')} – ${String(h + 1).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
        }
        let date_commande_formatted = '';
        if (c.date_commande) {
          const d = new Date(c.date_commande);
          const jour = d.getDate();
          const moisIdx = d.getMonth();
          const an = d.getFullYear();
          const heure = String(d.getHours()).padStart(2, '0');
          const min = String(d.getMinutes()).padStart(2, '0');
          date_commande_formatted = `${jour} ${mois[moisIdx]} ${an} · ${heure}:${min}`;
        }
        return {
          id: c.id,
          epicier_id: c.epicier_id,
          nom_boutique: c.store?.nom_boutique ?? '',
          date_commande: c.date_commande,
          date_recuperation: c.date_recuperation,
          date_commande_formatted: date_commande_formatted || null,
          creneau,
          montant_total: parseFloat(c.montant_total ?? 0),
          statut: c.statut,
          article_count: countMap[c.id] ?? 0,
        };
      });
      res.status(200).json(result);
    } catch (error) {
      console.error('Erreur getMyCommandes:', error);
      res.status(500).json({ message: 'Erreur lors de la récupération des commandes', error: error.message });
    }
  },

  getCommandeById: async (req, res) => {
    try {
      const clientId = req.user.id;
      const { id } = req.params;
      const commande = await Commande.findOne({
        where: { id, client_id: clientId },
        include: [{ model: Store, as: 'store', attributes: ['id', 'nom_boutique', 'telephone', 'adresse'] }],
      });
      if (!commande) {
        return res.status(404).json({ message: 'Commande introuvable' });
      }
      const details = await DetailCommande.findAll({
        where: { commande_id: commande.id },
        include: [{ model: Product, as: 'Product', attributes: ['id', 'nom', 'image_principale'] }],
      });
      let creneau = '';
      if (commande.date_recuperation) {
        const d = new Date(commande.date_recuperation);
        const h = d.getHours();
        const m = d.getMinutes();
        creneau = `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')} – ${String(h + 1).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
      }
      const lignes = details.map((d) => ({
        produit_id: d.produit_id,
        nom: d.Product?.nom ?? '',
        quantite: d.quantite,
        prix_unitaire: parseFloat(d.prix_unitaire ?? 0),
        total_ligne: parseFloat(d.total_ligne ?? 0),
      }));
      res.status(200).json({
        id: commande.id,
        epicier_id: commande.epicier_id,
        nom_boutique: commande.store?.nom_boutique ?? '',
        telephone_epicier: commande.store?.telephone ?? null,
        adresse_epicier: commande.store?.adresse ?? null,
        date_commande: commande.date_commande,
        date_recuperation: commande.date_recuperation,
        creneau,
        montant_total: parseFloat(commande.montant_total ?? 0),
        statut: commande.statut,
        article_count: lignes.reduce((s, l) => s + l.quantite, 0),
        lignes,
      });
    } catch (error) {
      console.error('Erreur getCommandeById:', error);
      res.status(500).json({ message: 'Erreur lors de la récupération de la commande', error: error.message });
    }
  },

  createFromPanier: async (req, res) => {
    try {
      const clientId = req.user.id;
      const { epicier_id, date_recuperation } = req.body;

      if (!epicier_id || !date_recuperation) {
        return res.status(400).json({ message: 'epicier_id et date_recuperation requis' });
      }

      const panierItems = cartStore.getItems(clientId);
      const produitIds = [...new Set(panierItems.map((i) => i.produit_id))];
      const products = await Product.findAll({
        where: { id: { [Op.in]: produitIds } },
        attributes: ['id', 'nom'],
      });
      const productNom = {};
      products.forEach((p) => { productNom[p.id] = p.nom; });

      const itemsForEpicier = [];
      const skipped = []; // { produit_id, nom } — plus disponible ou en rupture
      for (const row of panierItems) {
        const eid = row.epicier_id != null ? row.epicier_id : null;
        const matchEpicier = eid != null ? Number(eid) === Number(epicier_id) : false;
        if (!matchEpicier && eid !== null) continue;
        const ep = await EpicierProduct.findOne({
          where: eid != null
            ? { produit_id: row.produit_id, epicier_id: eid }
            : { produit_id: row.produit_id, epicier_id },
        });
        if (!ep) {
          skipped.push({ produit_id: row.produit_id, nom: productNom[row.produit_id] ?? 'Produit' });
          continue;
        }
        if (Number(ep.epicier_id) !== Number(epicier_id)) continue;
        if (!ep.is_active) {
          skipped.push({ produit_id: row.produit_id, nom: productNom[row.produit_id] ?? 'Produit' });
          continue;
        }
        if (ep.rupture_stock) {
          skipped.push({ produit_id: row.produit_id, nom: productNom[row.produit_id] ?? 'Produit' });
          continue;
        }
        const prix = parseFloat(ep.prix ?? 0);
        itemsForEpicier.push({ row, prix });
      }
      if (itemsForEpicier.length === 0) {
        const msg = skipped.length > 0
          ? `Aucun article disponible pour cet épicier. Les produits suivants n'existent plus ou sont en rupture : ${skipped.map((s) => s.nom).join(', ')}.`
          : 'Aucun article de cet épicier dans le panier';
        return res.status(400).json({ message: msg, skipped_products: skipped });
      }

      let montantTotal = 0;
      const details = itemsForEpicier.map(({ row, prix }) => {
        const qty = row.quantite || 0;
        const totalLigne = Math.round(prix * qty * 100) / 100;
        montantTotal += totalLigne;
        return {
          produit_id: row.produit_id,
          quantite: qty,
          prix_unitaire: prix,
          total_ligne: totalLigne,
        };
      });
      montantTotal = Math.round(montantTotal * 100) / 100;

      const dateRecup = new Date(date_recuperation);
      const commande = await Commande.create({
        client_id: clientId,
        epicier_id: Number(epicier_id),
        date_recuperation: dateRecup,
        montant_total: montantTotal,
      });

      await DetailCommande.bulkCreate(
        details.map((d) => ({
          commande_id: commande.id,
          produit_id: d.produit_id,
          quantite: d.quantite,
          prix_unitaire: d.prix_unitaire,
          total_ligne: d.total_ligne,
        }))
      );

      cartStore.removeItemsByProduitIds(clientId, itemsForEpicier.map(({ row }) => row.produit_id));

      res.status(201).json({
        message: 'Commande créée avec succès',
        commande_id: commande.id,
        montant_total: montantTotal,
        skipped_products: skipped,
      });
    } catch (error) {
      console.error('Erreur createFromPanier:', error);
      res.status(500).json({ message: 'Erreur lors de la création de la commande', error: error.message });
    }
  },

  // Commander à nouveau : ajoute au panier uniquement les produits encore disponibles (is_active, !rupture_stock).
  reorder: async (req, res) => {
    try {
      const clientId = req.user.id;
      const commandeId = req.params.id;
      const commande = await Commande.findOne({
        where: { id: commandeId, client_id: clientId },
      });
      if (!commande) {
        return res.status(404).json({ message: 'Commande introuvable' });
      }
      const details = await DetailCommande.findAll({
        where: { commande_id: commande.id },
        include: [{ model: Product, as: 'Product', attributes: ['id', 'nom'] }],
      });
      const epicierId = Number(commande.epicier_id);
      let addedCount = 0;
      const skipped = [];
      for (const d of details) {
        const ep = await EpicierProduct.findOne({
          where: { epicier_id: epicierId, produit_id: d.produit_id },
        });
        if (!ep || !ep.is_active || ep.rupture_stock) {
          skipped.push({ produit_id: d.produit_id, nom: d.Product?.nom ?? 'Produit' });
          continue;
        }
        const qty = Math.max(1, d.quantite || 1);
        cartStore.addItem(clientId, d.produit_id, qty, epicierId);
        addedCount += 1;
      }
      res.status(200).json({
        message: addedCount > 0 ? 'Produits disponibles ajoutés au panier.' : 'Aucun produit disponible à ajouter.',
        added_count: addedCount,
        skipped_products: skipped,
      });
    } catch (error) {
      console.error('Erreur reorder:', error);
      res.status(500).json({ message: 'Erreur lors de la réutilisation de la commande', error: error.message });
    }
  },
};

module.exports = commandeController;
