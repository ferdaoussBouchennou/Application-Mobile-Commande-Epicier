const { QueryTypes } = require('sequelize');
const sequelize = require('../config/db');

exports.getNotifications = async (req, res) => {
  try {
    const utilisateurId = req.user.id;
    const notifications = await sequelize.query(
      'SELECT id, utilisateur_id, message, date_envoi, lue FROM notifications WHERE utilisateur_id = :utilisateurId ORDER BY date_envoi DESC',
      { replacements: { utilisateurId }, type: QueryTypes.SELECT }
    );
    res.json(notifications);
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    await sequelize.query(
      'UPDATE notifications SET lue = 1 WHERE id = :id AND utilisateur_id = :utilisateurId',
      { replacements: { id, utilisateurId: req.user.id }, type: QueryTypes.UPDATE }
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

exports.markAllAsRead = async (req, res) => {
  try {
    await sequelize.query(
      'UPDATE notifications SET lue = 1 WHERE utilisateur_id = :utilisateurId',
      { replacements: { utilisateurId: req.user.id }, type: QueryTypes.UPDATE }
    );
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

exports.getUnreadCount = async (req, res) => {
  try {
    const [row] = await sequelize.query(
      'SELECT COUNT(*) as count FROM notifications WHERE utilisateur_id = :utilisateurId AND lue = 0',
      { replacements: { utilisateurId: req.user.id }, type: QueryTypes.SELECT }
    );
    res.json({ count: row?.count ?? 0 });
  } catch (err) {
    res.status(500).json({ message: 'Erreur serveur' });
  }
};
