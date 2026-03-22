const sequelize = require('../config/db');
const { QueryTypes } = require('sequelize');
const { sendNotification } = require('./notification');

/**
 * Envoie une notification à l'épicier : insertion en base + push FCM.
 * @param {number} epicierId - ID de l'épicier (store id)
 * @param {string} message - Message de la notification
 * @param {string} [title='MyHanut'] - Titre du push
 */
async function sendNotificationToEpicier(epicierId, message, title = 'MyHanut') {
  try {
    const rows = await sequelize.query(
      `SELECT u.fcm_token FROM epiciers e
       JOIN utilisateurs u ON e.utilisateur_id = u.id
       WHERE e.id = :epicierId`,
      { replacements: { epicierId }, type: QueryTypes.SELECT }
    );
    if (rows.length > 0 && rows[0].fcm_token) {
      await sendNotification(rows[0].fcm_token, title, message);
    }
    await sequelize.query(
      'INSERT INTO notifications_epicier (epicier_id, message, lue) VALUES (:epicier_id, :message, 0)',
      { replacements: { epicier_id: epicierId, message }, type: QueryTypes.INSERT }
    );
  } catch (e) {
    console.error('sendNotificationToEpicier error:', e);
  }
}

module.exports = { sendNotificationToEpicier };
