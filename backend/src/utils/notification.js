const { admin, firebaseInitialized } = require('../config/firebase/firebaseAdmin');
const User = require('../models/User');
const Notification = require('../models/Notification');

/**
 * Sends a push notification via FCM.
 */
const sendNotification = async (token, title, body, data = {}) => {
  if (!firebaseInitialized) {
    console.log(`[SIMULATION PUSH] To: ${token} | Title: ${title} | Body: ${body} | Data: ${JSON.stringify(data)}`);
    return;
  }

  const message = {
    notification: { title, body },
    data: data,
    token: token,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
  } catch (error) {
    console.error('Error sending message:', error);
  }
};

/**
 * Notifie tous les administrateurs ayant un token FCM.
 * Envoie un push ET enregistre dans la table notifications.
 */
const notifyAdmins = async (title, body, data = {}) => {
  try {
    const admins = await User.findAll({
      where: { role: 'ADMIN' }
    });

    if (admins.length === 0) {
      console.log('Aucun admin trouvé pour notification.');
      return;
    }

    const pushPromises = [];
    const dbPromises = [];

    admins.forEach(ad => {
      // 1. Sauvegarder en base de données
      dbPromises.push(Notification.create({
        client_id: ad.id,
        message: `${title}: ${body}`,
        lue: false
      }));

      // 2. Envoyer le Push si token présent
      if (ad.fcm_token) {
        pushPromises.push(sendNotification(ad.fcm_token, title, body, data));
      }
    });

    await Promise.all([...dbPromises, ...pushPromises]);
  } catch (error) {
    console.error('Erreur notifyAdmins:', error);
  }
};

module.exports = { sendNotification, notifyAdmins };
