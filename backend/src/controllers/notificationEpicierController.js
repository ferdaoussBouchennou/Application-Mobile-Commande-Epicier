const { QueryTypes } = require('sequelize');
const sequelize = require('../config/db');

exports.getNotifications = async (req, res) => {
  try {
    const clientId = req.user.id;
    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(50, Math.max(10, parseInt(req.query.limit, 10) || 20));
    const offset = (page - 1) * limit;
    const lueParam = req.query.lue;
    const onlyUnread = lueParam === '0' || lueParam === 'false';
    const onlyRead = lueParam === '1' || lueParam === 'true';

    let whereClause = 'WHERE client_id = :clientId';
    const replacements = { clientId };
    if (onlyUnread) {
      whereClause += ' AND lue = 0';
    } else if (onlyRead) {
      whereClause += ' AND lue = 1';
    }

    const notifications = await sequelize.query(
      `SELECT id, client_id, message, lue, date_envoi FROM notifications ${whereClause} ORDER BY date_envoi DESC LIMIT :limit OFFSET :offset`,
      { replacements: { ...replacements, limit, offset }, type: QueryTypes.SELECT }
    );

    const [countRows] = await sequelize.query(
      `SELECT COUNT(*) as total FROM notifications ${whereClause}`,
      { replacements, type: QueryTypes.SELECT }
    );
    const total = countRows?.[0]?.total ?? 0;

    res.json({
      items: notifications,
      pagination: { page, limit, total: Number(total), hasMore: offset + notifications.length < total },
    });
  } catch (err) {
    console.error('getNotifications epicier:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

exports.markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const clientId = req.user.id;
    await sequelize.query(
      'UPDATE notifications SET lue = 1 WHERE id = :id AND client_id = :clientId',
      { replacements: { id, clientId }, type: QueryTypes.UPDATE }
    );
    res.json({ success: true });
  } catch (err) {
    console.error('markAsRead epicier:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

exports.markAllAsRead = async (req, res) => {
  try {
    const clientId = req.user.id;
    await sequelize.query(
      'UPDATE notifications SET lue = 1 WHERE client_id = :clientId',
      { replacements: { clientId }, type: QueryTypes.UPDATE }
    );
    res.json({ success: true });
  } catch (err) {
    console.error('markAllAsRead epicier:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};

exports.getUnreadCount = async (req, res) => {
  try {
    const clientId = req.user.id;
    const [row] = await sequelize.query(
      'SELECT COUNT(*) as count FROM notifications WHERE client_id = :clientId AND lue = 0',
      { replacements: { clientId }, type: QueryTypes.SELECT }
    );
    res.json({ count: row?.count ?? 0 });
  } catch (err) {
    console.error('getUnreadCount epicier:', err);
    res.status(500).json({ message: 'Erreur serveur' });
  }
};
