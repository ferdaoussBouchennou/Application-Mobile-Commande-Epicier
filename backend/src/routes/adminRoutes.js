const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');

// Middleware d'admin pourrait être ajouté ici

router.get('/stats', adminController.getStats);
router.get('/users', adminController.getUsers);
router.patch('/users/:id/status', adminController.updateUserStatus);
router.post('/register-epicier', adminController.registerEpicier);

module.exports = router;
