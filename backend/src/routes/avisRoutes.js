const express = require('express');
const router = express.Router();
const avisController = require('../controllers/avisController');
const { authMiddleware } = require('../middlewares/auth');

router.get('/commande/:commandeId', authMiddleware, avisController.getByCommande);
router.post('/', authMiddleware, avisController.createOrUpdate);

module.exports = router;
