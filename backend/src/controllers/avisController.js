const sequelize = require('../config/db');
const { QueryTypes } = require('sequelize');
const Avis = require('../models/Avis');
const Commande = require('../models/Commande');
const Store = require('../models/Store');

const avisController = {
  // GET /avis/commande/:commandeId — get current user's avis for this order (to show existing or allow submit)
  getByCommande: async (req, res) => {
    try {
      const clientId = req.user.id;
      const { commandeId } = req.params;
      const commande = await Commande.findOne({
        where: { id: commandeId, client_id: clientId },
      });
      if (!commande) {
        return res.status(404).json({ message: 'Commande introuvable' });
      }
      const avis = await Avis.findOne({
        where: { commande_id: commandeId },
      });
      if (!avis) {
        return res.status(200).json({ avis: null });
      }
      res.status(200).json({
        avis: {
          id: avis.id,
          commande_id: avis.commande_id,
          note: avis.note,
          commentaire: avis.commentaire || '',
          date_avis: avis.date_avis,
        },
      });
    } catch (error) {
      console.error('Erreur getByCommande avis:', error);
      res.status(500).json({ message: 'Erreur lors de la récupération de l\'avis', error: error.message });
    }
  },

  // POST /avis — create or update avis for a commande (client only, commande must be livrée and belong to client)
  createOrUpdate: async (req, res) => {
    try {
      const clientId = req.user.id;
      const { commande_id, note, commentaire } = req.body;
      if (!commande_id || note == null) {
        return res.status(400).json({ message: 'commande_id et note requis' });
      }
      const noteNum = parseInt(note, 10);
      if (isNaN(noteNum) || noteNum < 1 || noteNum > 5) {
        return res.status(400).json({ message: 'La note doit être entre 1 et 5' });
      }
      const commande = await Commande.findOne({
        where: { id: commande_id, client_id: clientId },
      });
      if (!commande) {
        return res.status(404).json({ message: 'Commande introuvable' });
      }
      if (commande.statut !== 'livrée') {
        return res.status(400).json({ message: 'Vous ne pouvez noter qu\'une commande récupérée (livrée).' });
      }
      const [avis, created] = await Avis.findOrCreate({
        where: { commande_id: commande_id },
        defaults: {
          client_id: clientId,
          epicier_id: commande.epicier_id,
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
        { replacements: { eid: commande.epicier_id }, type: QueryTypes.SELECT }
      );
      const moy = (rows && rows[0] && rows[0].moy != null) ? Number(Number(rows[0].moy).toFixed(1)) : 0;
      await Store.update({ rating: moy }, { where: { id: commande.epicier_id } });
      res.status(200).json({
        message: created ? 'Avis enregistré' : 'Avis modifié',
        avis: { id: avis.id, note: avis.note, commentaire: avis.commentaire },
      });
    } catch (error) {
      console.error('Erreur createOrUpdate avis:', error);
      res.status(500).json({ message: 'Erreur lors de l\'enregistrement de l\'avis', error: error.message });
    }
  },
};

module.exports = avisController;
