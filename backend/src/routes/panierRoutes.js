const express = require('express');
const router = express.Router();
const panierController = require('../controllers/panierController');
const { authMiddleware } = require('../middlewares/auth');

router.use(authMiddleware);

router.get('/', panierController.getPanier);
router.post('/items', panierController.addItem);
router.put('/items/:produitId', panierController.updateQuantity);
router.delete('/items/:produitId', panierController.removeItem);

module.exports = router;
