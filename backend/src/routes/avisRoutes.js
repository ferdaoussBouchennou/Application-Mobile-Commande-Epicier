const express = require('express');
const router = express.Router();
const avisController = require('../controllers/avisController');
const { authMiddleware } = require('../middlewares/auth');

router.get('/store/:epicierId', authMiddleware, avisController.getByStoreClient);
router.post('/', authMiddleware, avisController.createOrUpdate);

module.exports = router;
