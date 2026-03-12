const express = require('express');
const router = express.Router();
const grocerController = require('../controllers/grocerController');
const { authMiddleware, requireEpicier } = require('../middlewares/auth');

router.get('/dashboard', authMiddleware, requireEpicier, grocerController.getDashboard);
router.get('/commandes', authMiddleware, requireEpicier, grocerController.getCommandes);
router.patch('/commandes/:id/statut', authMiddleware, requireEpicier, grocerController.updateCommandeStatut);

module.exports = router;
