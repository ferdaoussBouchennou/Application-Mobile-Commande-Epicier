const Reclamation = require('../models/Reclamation');
const Commande = require('../models/Commande');
const { sendNotificationToEpicier } = require('../utils/notificationEpicier');

exports.create = async (req, res) => {
  try {
    const clientId = req.user.id;
    const { id } = req.params;
    const { description } = req.body;
    if (!description || typeof description !== 'string' || !description.trim()) {
      return res.status(400).json({ message: 'La description est requise' });
    }
    const commande = await Commande.findOne({
      where: { id, client_id: clientId },
    });
    if (!commande) {
      return res.status(404).json({ message: 'Commande introuvable' });
    }
    const existing = await Reclamation.findOne({
      where: { commande_id: id, client_id: clientId },
    });
    if (existing) {
      return res.status(400).json({ message: 'Une réclamation existe déjà pour cette commande' });
    }
    const reclamation = await Reclamation.create({
      client_id: clientId,
      commande_id: id,
      description: description.trim(),
      statut: 'Litige ouvert',
    });
    sendNotificationToEpicier(
      commande.epicier_id,
      `Nouvelle réclamation pour la commande #${id} : "${description.trim().slice(0, 100)}${description.trim().length > 100 ? '...' : ''}"`,
      'Nouvelle réclamation'
    ).catch(() => {});
    res.status(201).json({
      message: 'Réclamation enregistrée',
      reclamation: { id: reclamation.id, description: reclamation.description },
    });
  } catch (error) {
    console.error('Erreur create reclamation:', error);
    res.status(500).json({ message: 'Erreur lors de l\'enregistrement', error: error.message });
  }
};
