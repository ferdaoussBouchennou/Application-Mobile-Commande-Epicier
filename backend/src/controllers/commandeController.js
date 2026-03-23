const sequelize = require('../config/db');
const { QueryTypes } = require('sequelize');
const Commande = require('../models/Commande');
const { sendNotificationToEpicier } = require('../utils/notificationEpicier');
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
      if (statutFilter && ['reçue', 'prête', 'livrée', 'refusee'].includes(statutFilter)) {
        where.statut = statutFilter;
      }
      if (epicierFilter) {
        where.epicier_id = Number(epicierFilter);
      }
      const commandes = await Commande.findAll({
        where,
        include: [{ model: Store, as: 'epicier', attributes: ['id', 'nom_boutique'] }],
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
          nom_boutique: c.epicier?.nom_boutique ?? '',
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
        include: [{ model: Store, as: 'epicier', attributes: ['id', 'nom_boutique', 'telephone', 'adresse'] }],
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
      const hasRupture = details.some((d) => !!d.rupture);
      const hasPendingAcceptance = details.some((d) => !!d.en_attente_acceptation_client);
      const lignes = details.map((d) => ({
        detail_id: d.id,
        produit_id: d.produit_id,
        nom: d.Product?.nom ?? '',
        quantite: d.quantite,
        prix_unitaire: parseFloat(d.prix_unitaire ?? 0),
        total_ligne: parseFloat(d.total_ligne ?? 0),
        rupture: !!d.rupture,
        en_attente_acceptation_client: !!d.en_attente_acceptation_client,
      }));
      res.status(200).json({
        id: commande.id,
        epicier_id: commande.epicier_id,
        nom_boutique: commande.epicier?.nom_boutique ?? '',
        telephone_epicier: commande.epicier?.telephone ?? null,
        adresse_epicier: commande.epicier?.adresse ?? null,
        date_commande: commande.date_commande,
        date_recuperation: commande.date_recuperation,
        creneau,
        montant_total: parseFloat(commande.montant_total ?? 0),
        statut: commande.statut,
        message_refus: commande.message_refus ?? null,
        article_count: lignes.reduce((s, l) => s + l.quantite, 0),
        client_accepte_modification: !!commande.client_accepte_modification,
        has_rupture: hasRupture,
        has_pending_acceptance: hasPendingAcceptance,
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

      sendNotificationToEpicier(
        Number(epicier_id),
        `Nouvelle commande #${commande.id} reçue (${montantTotal.toFixed(2)} MAD).`,
        'Nouvelle commande'
      ).catch(() => {});

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

  accepterProduitRemisEnStock: async (req, res) => {
    try {
      const clientId = req.user.id;
      const { id, detailId } = req.params;
      const commande = await Commande.findOne({
        where: { id, client_id: clientId },
      });
      if (!commande) {
        return res.status(404).json({ message: 'Commande introuvable' });
      }
      const detail = await DetailCommande.findOne({
        where: { id: detailId, commande_id: id },
        include: [{ model: Product, attributes: ['nom'] }],
      });
      if (!detail) {
        return res.status(404).json({ message: 'Ligne de commande introuvable' });
      }
      if (!detail.en_attente_acceptation_client) {
        return res.status(400).json({ message: 'Ce produit n\'est pas en attente d\'acceptation.' });
      }
      detail.en_attente_acceptation_client = 0;
      await detail.save();
      const produitNom = detail.Product?.nom ?? 'Un produit';
      sendNotificationToEpicier(
        commande.epicier_id,
        `Le client a accepté d'ajouter le produit "${produitNom}" à la commande #${id}.`,
        'Produit accepté'
      ).catch(() => {});
      res.status(200).json({ message: 'Produit accepté dans la commande.', detail_id: detail.id });
    } catch (error) {
      console.error('Erreur accepterProduitRemisEnStock:', error);
      res.status(500).json({ message: 'Erreur lors de l\'acceptation du produit', error: error.message });
    }
  },

  accepterModifications: async (req, res) => {
    try {
      const clientId = req.user.id;
      const { id } = req.params;
      const commande = await Commande.findOne({
        where: { id, client_id: clientId },
      });
      if (!commande) {
        return res.status(404).json({ message: 'Commande introuvable' });
      }
      if (commande.statut !== 'reçue' && commande.statut !== 'prête') {
        return res.status(400).json({ message: 'Cette commande n\'est plus modifiable.' });
      }
      const hasRupture = await DetailCommande.findOne({
        where: { commande_id: id, rupture: 1 },
      });
      if (!hasRupture) {
        return res.status(400).json({ message: 'Aucune rupture à accepter.' });
      }
      commande.client_accepte_modification = 1;
      await commande.save();
      sendNotificationToEpicier(
        commande.epicier_id,
        `Le client a accepté les modifications (ruptures) de la commande #${id}. Vous pouvez accepter la commande.`,
        'Client a accepté'
      ).catch(() => {});
      res.status(200).json({ message: 'Modifications acceptées.', client_accepte_modification: true });
    } catch (error) {
      console.error('Erreur accepterModifications:', error);
      res.status(500).json({ message: 'Erreur lors de l\'acceptation', error: error.message });
    }
  },

  annulerCommande: async (req, res) => {
    try {
      const clientId = req.user.id;
      const { id } = req.params;
      const { message: motif } = req.body || {};
      const commande = await Commande.findOne({
        where: { id, client_id: clientId },
      });
      if (!commande) {
        return res.status(404).json({ message: 'Commande introuvable' });
      }
      if (commande.statut !== 'reçue' && commande.statut !== 'prête') {
        return res.status(400).json({ message: 'Seules les commandes reçues ou prêtes peuvent être annulées.' });
      }
      commande.statut = 'refusee';
      if (motif && typeof motif === 'string' && motif.trim()) {
        commande.message_refus = motif.trim();
      }
      await commande.save();
      let notifMsg = `Le client a annulé la commande #${id}.`;
      if (commande.message_refus) {
        notifMsg += ` Motif : "${String(commande.message_refus).slice(0, 80)}${commande.message_refus.length > 80 ? '...' : ''}"`;
      }
      sendNotificationToEpicier(commande.epicier_id, notifMsg, 'Commande annulée').catch(() => {});
      res.status(200).json({ message: 'Commande annulée.', statut: commande.statut });
    } catch (error) {
      console.error('Erreur annulerCommande:', error);
      res.status(500).json({ message: 'Erreur lors de l\'annulation', error: error.message });
    }
  },

  refuserModifications: async (req, res) => {
    try {
      const clientId = req.user.id;
      const { id } = req.params;
      const { message: messageRefus } = req.body || {};
      const commande = await Commande.findOne({
        where: { id, client_id: clientId },
      });
      if (!commande) {
        return res.status(404).json({ message: 'Commande introuvable' });
      }
      if (commande.statut !== 'reçue' && commande.statut !== 'prête') {
        return res.status(400).json({ message: 'Cette commande n\'est plus modifiable.' });
      }
      const hasRupture = await DetailCommande.findOne({
        where: { commande_id: id, rupture: 1 },
      });
      if (!hasRupture) {
        return res.status(400).json({ message: 'Aucune rupture. Utilisez une réclamation si besoin.' });
      }
      commande.statut = 'refusee';
      if (messageRefus && typeof messageRefus === 'string' && messageRefus.trim()) {
        commande.message_refus = messageRefus.trim();
      }
      await commande.save();
      let notifMsg = `Le client a refusé la commande #${id} suite aux ruptures de stock.`;
      if (commande.message_refus) {
        notifMsg += ` Motif : "${String(commande.message_refus).slice(0, 80)}${commande.message_refus.length > 80 ? '...' : ''}"`;
      }
      sendNotificationToEpicier(commande.epicier_id, notifMsg, 'Commande refusée').catch(() => {});
      res.status(200).json({ message: 'Commande refusée.', statut: commande.statut });
    } catch (error) {
      console.error('Erreur refuserModifications:', error);
      res.status(500).json({ message: 'Erreur lors du refus', error: error.message });
    }
  },

  refuserProduitRemisEnStock: async (req, res) => {
    try {
      const clientId = req.user.id;
      const { id, detailId } = req.params;
      const commande = await Commande.findOne({
        where: { id, client_id: clientId },
      });
      if (!commande) {
        return res.status(404).json({ message: 'Commande introuvable' });
      }
      const detail = await DetailCommande.findOne({
        where: { id: detailId, commande_id: id },
        include: [{ model: Product, attributes: ['nom'] }],
      });
      if (!detail) {
        return res.status(404).json({ message: 'Ligne de commande introuvable' });
      }
      if (!detail.en_attente_acceptation_client) {
        return res.status(400).json({ message: 'Ce produit n\'est pas en attente d\'acceptation.' });
      }
      const produitNom = detail.Product?.nom ?? 'Un produit';
      await DetailCommande.destroy({ where: { id: detailId, commande_id: id } });
      const allDetails = await DetailCommande.findAll({
        where: { commande_id: id },
      });
      const newTotal = allDetails
        .filter((d) => !d.rupture)
        .reduce((sum, d) => sum + parseFloat(d.total_ligne ?? 0), 0);
      commande.montant_total = newTotal;
      await commande.save();
      const msg = `Le client a refusé d'ajouter le produit "${produitNom}" à la commande #${id}. Le produit a été retiré (nouveau total: ${newTotal.toFixed(2)} MAD). Vous pouvez accepter la commande.`;
      sendNotificationToEpicier(commande.epicier_id, msg, 'Produit refusé').catch(() => {});
      res.status(200).json({
        message: 'Produit retiré de la commande. L\'épicier a été notifié.',
        montant_total: newTotal,
      });
    } catch (error) {
      console.error('Erreur refuserProduitRemisEnStock:', error);
      res.status(500).json({ message: 'Erreur lors du refus du produit', error: error.message });
    }
  },
};

module.exports = commandeController;
