const { QueryTypes } = require('sequelize');
const sequelize = require('../config/db');

exports.getNotifications = async (req, res) => {
  try {
    const epicierId = req.user.storeId;
    if (!epicierId) {
      return res.status(403).json({ message: 'Store ID manquant' });
    }
    const notifications = await sequelize.query(
      'SELECT id, epicier_id, message, lue, created_at as date_envoi FROM notifications_epicier WHERE epicier_id = :epicierId ORDER BY created_at DESC',
      { replacements: { epicierId }, type: QueryTypes.SELECT }
    );
    res.json(notifications);
  } catch (err) {
    console.error('getNotifications epicier:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const epicierId = req.user.storeId;
    if (!epicierId) {
      return res.status(403).json({ message: 'Store ID manquant' });
    }
    await sequelize.query(
      'UPDATE notifications_epicier SET lue = 1 WHERE id = :id AND epicier_id = :epicierId',
      { replacements: { id, epicierId }, type: QueryTypes.UPDATE }
    );
    res.json({ success: true });
  } catch (err) {
    console.error('markAsRead epicier:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

exports.markAllAsRead = async (req, res) => {
  try {
    const epicierId = req.user.storeId;
    if (!epicierId) {
      return res.status(403).json({ message: 'Store ID manquant' });
    }
    await sequelize.query(
      'UPDATE notifications_epicier SET lue = 1 WHERE epicier_id = :epicierId',
      { replacements: { epicierId }, type: QueryTypes.UPDATE }
    );
    res.json({ success: true });
  } catch (err) {
    console.error('markAllAsRead epicier:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

exports.getUnreadCount = async (req, res) => {
  try {
    const epicierId = req.user.storeId;
    if (!epicierId) {
      return res.status(403).json({ message: 'Store ID manquant' });
    }
    const [row] = await sequelize.query(
      'SELECT COUNT(*) as count FROM notifications_epicier WHERE epicier_id = :epicierId AND lue = 0',
      { replacements: { epicierId }, type: QueryTypes.SELECT }
    );
    res.json({ count: row?.count ?? 0 });
  } catch (err) {
    console.error('getUnreadCount epicier:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};
