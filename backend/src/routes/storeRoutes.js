const express = require('express');
const router = express.Router();
const storeController = require('../controllers/storeController');

// Routes pour les épiciers
router.get('/', storeController.getAllStores);
router.get('/:id/creneaux', storeController.getCreneaux);
router.get('/:id', storeController.getStoreById);

module.exports = router;
