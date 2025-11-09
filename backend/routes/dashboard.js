import express from 'express';
import { verifyToken } from '../middlewares/authMiddleware.js';
import { getDashboard } from '../controllers/dashboardController.js';

const router = express.Router();
router.get('/', verifyToken, getDashboard);
export default router;
