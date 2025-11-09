import express from 'express';
import { verifyToken, isAdmin } from '../middlewares/authMiddleware.js';
import { solicitarLivro, minhasSolicitacoes, listarPendentes, aprovarSolicitacao, rejeitarSolicitacao } from '../controllers/solicitacaoController.js';

const router = express.Router();

// usuário comum
router.post('/', verifyToken, solicitarLivro);
router.get('/me', verifyToken, minhasSolicitacoes);

// admin
router.get('/', verifyToken, isAdmin, listarPendentes);
router.put('/:id/approve', verifyToken, isAdmin, aprovarSolicitacao);
router.put('/:id/reject', verifyToken, isAdmin, rejeitarSolicitacao);

export default router;
