const { admin, firebaseInitialized } = require('../config/firebase/firebaseAdmin');

/**
 * Sends a push notification via FCM.
 */
const sendNotification = async (token, title, body) => {
  if (!firebaseInitialized) {
    console.log(`[SIMULATION PUSH] To: ${token} | Title: ${title} | Body: ${body}`);
    return;
  }

  const message = {
    notification: { title, body },
    token: token,
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
  } catch (error) {
    console.error('Error sending message:', error);
  }
};

module.exports = { sendNotification };
