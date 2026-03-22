const sequelize = require('../config/db');
const { QueryTypes } = require('sequelize');
const Avis = require('../models/Avis');
const Commande = require('../models/Commande');
const Store = require('../models/Store');

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
