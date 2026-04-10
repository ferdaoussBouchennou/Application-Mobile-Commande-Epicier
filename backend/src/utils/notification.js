const { admin, firebaseInitialized } = require('../config/firebase/firebaseAdmin');
const User = require('../models/User');
const Notification = require('../models/Notification');

/**
 * Sends a push notification via FCM.
 * @param {string} token - FCM token
 * @param {string} title - Title
 * @param {string} body - Body
 * @param {object} data - Extra data
 * @param {boolean} silent - If true, sends a data-only message (no system banner)
 */
const sendNotification = async (token, title, body, data = {}, silent = false) => {
  if (!firebaseInitialized) {
    console.log(`[SIMULATION PUSH] To: ${token} | Title: ${title} | Body: ${body} | Data: ${JSON.stringify(data)} | Silent: ${silent}`);
    return;
  }

  const message = {
    data: { ...data, title, body }, // Always include title/body in data for app internal processing
    token: token,
  };

  // Only add 'notification' block if NOT silent
  if (!silent) {
    message.notification = { title, body };
    message.android = {
      priority: 'high',
      notification: { 
        sound: 'default'
      }
    };
    message.apns = {
      payload: {
        aps: {
          sound: 'default'
        }
      }
    };
  }

  try {
    const response = await admin.messaging().send(message);
    console.log(`Successfully sent message (${silent ? 'silent' : 'banner'}):`, response);
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
        utilisateur_id: ad.id,
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

/**
 * Envoie une notification à un utilisateur spécifique.
 * Sauvegarde en base ET envoie un push (silencieux ou bannière).
 */
const sendNotificationToUser = async (userId, title, body, data = {}, silent = false) => {
  try {
    // 1. Sauvegarde en base de données
    await Notification.create({
      utilisateur_id: userId,
      message: body, // On stocke juste le corps ou le titre+corps selon vos préférences
      lue: false
    });

    // 2. Envoi du Push si l'utilisateur a un token
    const user = await User.findByPk(userId);
    if (user && user.fcm_token) {
      await sendNotification(user.fcm_token, title, body, data, silent);
    }
  } catch (error) {
    console.error('Erreur sendNotificationToUser:', error);
  }
};

module.exports = { sendNotification, notifyAdmins, sendNotificationToUser };
