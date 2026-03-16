const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

const serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');
let firebaseInitialized = false;

if (fs.existsSync(serviceAccountPath)) {
  try {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('Firebase Admin initialized successfully.');
    firebaseInitialized = true;
  } catch (error) {
    console.error('Error initializing Firebase Admin:', error);
  }
} else {
  console.warn('Firebase Admin NOT initialized: Service account key missing at', serviceAccountPath);
  console.warn('Push notifications will be simulated (logged to console).');
}

module.exports = { admin, firebaseInitialized };
