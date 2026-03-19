const sequelize = require('../config/db');
const { QueryTypes } = require('sequelize');
const Commande = require('../models/Commande');
const DetailCommande = require('../models/DetailCommande');
const Product = require('../models/Product');
const EpicierProduct = require('../models/EpicierProduct');
const Store = require('../models/Store');

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
      const { epicier_id, date_recuperation, items } = req.body; // items: [{ produit_id, quantite }]

      if (!epicier_id || !date_recuperation || !items || !Array.isArray(items) || items.length === 0) {
        return res.status(400).json({ message: 'Données de commande incomplètes (epicier_id, date_recuperation, items requis)' });
      }

      const itemsForEpicier = [];
      for (const item of items) {
        const ep = await EpicierProduct.findOne({
          where: { produit_id: item.produit_id, epicier_id },
        });
        if (!ep) continue;
        
        const prix = parseFloat(ep.prix ?? 0);
        const qty = item.quantite || 0;
        const totalLigne = Math.round(prix * qty * 100) / 100;

        itemsForEpicier.push({
          produit_id: item.produit_id,
          quantite: qty,
          prix_unitaire: prix,
          total_ligne: totalLigne
        });
      }

      if (itemsForEpicier.length === 0) {
        return res.status(400).json({ message: 'Aucun article valide de cet épicier dans votre commande' });
      }

      const montantTotal = itemsForEpicier.reduce((sum, item) => sum + item.total_ligne, 0);

      const commande = await Commande.create({
        client_id: clientId,
        epicier_id: Number(epicier_id),
        date_recuperation: new Date(date_recuperation),
        montant_total: Math.round(montantTotal * 100) / 100,
        statut: 'reçue',
        date_commande: new Date()
      });

      await DetailCommande.bulkCreate(
        itemsForEpicier.map((d) => ({
          commande_id: commande.id,
          produit_id: d.produit_id,
          quantite: d.quantite,
          prix_unitaire: d.prix_unitaire,
          total_ligne: d.total_ligne,
        }))
      );

      res.status(201).json({
        message: 'Commande créée avec succès',
        commande_id: commande.id,
        montant_total: Math.round(montantTotal * 100) / 100,
      });
    } catch (error) {
      console.error('Erreur createCommande:', error);
      res.status(500).json({ message: 'Erreur lors de la création de la commande', error: error.message });
    }
  },
};

module.exports = commandeController;
