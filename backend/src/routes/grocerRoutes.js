const express = require('express');
const router = express.Router();
const grocerController = require('../controllers/grocerController');
const { authMiddleware, requireEpicier } = require('../middlewares/auth');

router.get('/dashboard', authMiddleware, requireEpicier, grocerController.getDashboard);

module.exports = router;
