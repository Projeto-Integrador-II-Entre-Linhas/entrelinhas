// routes/solicitacoes.js
import express from 'express';
import { verifyToken } from '../middlewares/authMiddleware.js';
import { solicitarLivro } from '../controllers/solicitacaoController.js';

const router = express.Router();
router.post('/', verifyToken, solicitarLivro);
export default router;
