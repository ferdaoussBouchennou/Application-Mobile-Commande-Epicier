const express = require('express');
const router = express.Router();
const clientRoutes = require('./clientRoutes');
const adminRoutes = require('./adminRoutes');

// Health check
router.get('/health', (req, res) => {
  res.json({ status: 'OK' });
});

// Main routes
router.use('/client', clientRoutes);
router.use('/admin', adminRoutes);

module.exports = router;
