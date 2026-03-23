const sequelize = require('../config/db');
const { QueryTypes, Op } = require('sequelize');
const Avis = require('../models/Avis');
const Commande = require('../models/Commande');
const Store = require('../models/Store');
const User = require('../models/User');
const Reclamation = require('../models/Reclamation');
const { sendNotificationToEpicier } = require('../utils/notificationEpicier');

const avisController = {
  // GET /avis/store/:epicierId — get current user's avis for this store
  getByStoreClient: async (req, res) => {
    try {
      const clientId = req.user.id;
      const { epicierId } = req.params;

      const avis = await Avis.findOne({
        where: { client_id: clientId, epicier_id: epicierId },
      });
      if (!avis) {
        return res.status(200).json({ avis: null });
      }
      res.status(200).json({
        avis: {
          id: avis.id,
          note: avis.note,
          commentaire: avis.commentaire || '',
          date_avis: avis.date_avis,
        },
      });
    } catch (error) {
      console.error('Erreur getByStoreClient avis:', error);
      res.status(500).json({ message: 'Erreur lors de la récupération de l\'avis', error: error.message });
    }
  },

  // POST /avis — create or update avis for a store (client only, must have at least one commande livrée from this store)
  createOrUpdate: async (req, res) => {
    try {
      const clientId = req.user.id;
      const { epicier_id, note, commentaire } = req.body;
      if (!epicier_id || note == null) {
        return res.status(400).json({ message: 'epicier_id et note requis' });
      }
      const noteNum = parseInt(note, 10);
      if (isNaN(noteNum) || noteNum < 1 || noteNum > 5) {
        return res.status(400).json({ message: 'La note doit être entre 1 et 5' });
      }
      // Check if the client has at least one 'livrée' order for this grocer
      const hasLivreeOrder = await Commande.findOne({
        where: { client_id: clientId, epicier_id: epicier_id, statut: 'livrée' },
      });

      if (!hasLivreeOrder) {
        return res.status(400).json({ message: 'Vous ne pouvez noter qu\'un épicier chez qui vous avez déjà une commande livrée.' });
      }

      const [avis, created] = await Avis.findOrCreate({
        where: { client_id: clientId, epicier_id: epicier_id },
        defaults: {
          note: noteNum,
          commentaire: commentaire ? String(commentaire).trim() || null : null,
        },
      });
      if (!created) {
        avis.note = noteNum;
        avis.commentaire = commentaire ? String(commentaire).trim() || null : null;
        await avis.save();
      }
      // Update store rating (average of all avis for this epicier)
      const rows = await sequelize.query(
        'SELECT COALESCE(AVG(note), 0) AS moy FROM avis WHERE epicier_id = :eid',
        { replacements: { eid: epicier_id }, type: QueryTypes.SELECT }
      );
      const moy = (rows && rows[0] && rows[0].moy != null) ? Number(Number(rows[0].moy).toFixed(1)) : 0;
      await Store.update({ rating: moy }, { where: { id: epicier_id } });
      sendNotificationToEpicier(
        epicier_id,
        `Nouvel avis reçu : ${noteNum}/5${commentaire ? ` — "${String(commentaire).slice(0, 80)}${String(commentaire).length > 80 ? '...' : ''}"` : ''} (commande #${hasLivreeOrder.id})`,
        'Nouvel avis'
      ).catch(() => {});
      res.status(200).json({
        message: created ? 'Avis enregistré' : 'Avis modifié',
        avis: { id: avis.id, note: avis.note, commentaire: avis.commentaire },
      });
    } catch (error) {
      console.error('Erreur createOrUpdate avis:', error);
      res.status(500).json({ message: 'Erreur lors de l\'enregistrement de l\'avis', error: error.message });
    }
  },

  // GET /epicier/avis — list store reviews with report status (from reclamations table)
  getStoreAvisForEpicier: async (req, res) => {
    try {
      const epicierId = req.user.storeId;
      if (!epicierId) {
        return res.status(403).json({ message: 'Store ID manquant' });
      }

      const avisList = await Avis.findAll({
        where: { epicier_id: epicierId },
        include: [{ model: User, as: 'client', attributes: ['nom', 'prenom'] }],
        order: [['date_avis', 'DESC']],
      });

      const avisIds = avisList.map((a) => a.id);
      let reclamationsByAvis = {};

      if (avisIds.length > 0) {
        const reclamations = await Reclamation.findAll({
          where: { epicier_id: epicierId, avis_id: avisIds, type: 'AVIS' },
          order: [['date_creation', 'DESC']],
        });

        reclamationsByAvis = reclamations.reduce((acc, r) => {
          const key = r.avis_id;
          if (!acc[key]) acc[key] = [];
          acc[key].push({
            id: r.id,
            motif: r.motif,
            description: r.description,
            preuve: r.preuve,
            statut: r.statut,
            date_creation: r.date_creation,
          });
          return acc;
        }, {});
      }

      const data = avisList.map((a) => ({
        id: a.id,
        note: a.note,
        commentaire: a.commentaire || '',
        date_avis: a.date_avis,
        client_nom: a.client ? `${a.client.prenom || ''} ${a.client.nom || ''}`.trim() : 'Client',
        contestations: reclamationsByAvis[a.id] || [],
      }));

      res.status(200).json({ avis: data });
    } catch (error) {
      console.error('Erreur getStoreAvisForEpicier:', error);
      res.status(500).json({ message: 'Erreur lors de la récupération des avis', error: error.message });
    }
  },

  // POST /epicier/avis/:id/reclamations — report review using reclamations table
  createAvisReclamation: async (req, res) => {
    try {
      const epicierId = req.user.storeId;
      const avisId = parseInt(req.params.id, 10);
      const { motif, description } = req.body;

      if (!epicierId) {
        return res.status(403).json({ message: 'Store ID manquant' });
      }
      if (Number.isNaN(avisId)) {
        return res.status(400).json({ message: 'Identifiant avis invalide' });
      }
      if (!motif || typeof motif !== 'string' || !motif.trim()) {
        return res.status(400).json({ message: 'Le motif est requis' });
      }
      const avis = await Avis.findOne({ where: { id: avisId, epicier_id: epicierId } });
      if (!avis) {
        return res.status(404).json({ message: 'Avis introuvable pour votre boutique' });
      }

      const existingActive = await Reclamation.findOne({
        where: {
          avis_id: avisId,
          epicier_id: epicierId,
          type: 'AVIS',
          statut: { [Op.in]: ['En attente', 'En médiation', 'Litige ouvert'] },
        },
      });
      if (existingActive) {
        return res.status(400).json({
          message: 'Une contestation est déjà en cours pour cet avis',
          reclamation_id: existingActive.id,
        });
      }

      const reclamation = await Reclamation.create({
        client_id: avis.client_id,
        commande_id: null,
        avis_id: avisId,
        epicier_id: epicierId,
        motif: motif.trim(),
        description: description ? String(description).trim() || 'Signalement d\'avis' : 'Signalement d\'avis',
        type: 'AVIS',
        statut: 'En attente',
      });

      res.status(201).json({
        message: 'Contestation envoyée avec succès',
        reclamation: {
          id: reclamation.id,
          avis_id: reclamation.avis_id,
          statut: reclamation.statut,
          date_creation: reclamation.date_creation,
        },
      });
    } catch (error) {
      console.error('Erreur createAvisReclamation:', error);
      res.status(500).json({ message: 'Erreur lors de la création de la contestation', error: error.message });
    }
  },
};

module.exports = avisController;
