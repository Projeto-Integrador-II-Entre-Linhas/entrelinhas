import express from 'express';
import { upsertFichamento, getFichamentosPublicos } from '../controllers/fichamentoController.js';
import { verifyToken } from '../middlewares/authMiddleware.js';

const router = express.Router();

router.get('/publicos', getFichamentosPublicos);
router.post('/', verifyToken, upsertFichamento);

export default router;
