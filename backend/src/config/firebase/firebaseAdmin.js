const path = require('path');
const fs = require('fs');

let admin = null;
let firebaseInitialized = false;

try {
  admin = require('firebase-admin');
} catch (e) {
  console.warn('firebase-admin not installed. Run: npm install firebase-admin');
  console.warn('Push notifications will be simulated (logged to console).');
}

if (admin && fs.existsSync(path.join(__dirname, 'serviceAccountKey.json'))) {
  try {
    const serviceAccount = require(path.join(__dirname, 'serviceAccountKey.json'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('Firebase Admin initialized successfully.');
    firebaseInitialized = true;
  } catch (error) {
    console.error('Error initializing Firebase Admin:', error);
  }
} else if (!admin) {
  console.warn('Push notifications will be simulated (logged to console).');
} else {
  console.warn('Firebase Admin NOT initialized: Service account key missing at', path.join(__dirname, 'serviceAccountKey.json'));
  console.warn('Push notifications will be simulated (logged to console).');
}

module.exports = { admin, firebaseInitialized };
