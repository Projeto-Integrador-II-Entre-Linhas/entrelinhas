import express from 'express';
import { verifyToken, isAdmin } from '../middlewares/authMiddleware.js';
import {
  solicitarLivro,
  minhasSolicitacoes,
  listarPendentes,
  aprovarSolicitacao,
  rejeitarSolicitacao,
  detalheSolicitacao,
  atualizarSolicitacao
} from '../controllers/solicitacaoController.js';

const router = express.Router();

// === Usuário comum ===
router.post('/', verifyToken, solicitarLivro);
router.get('/me', verifyToken, minhasSolicitacoes);

// === Admin ===
router.get('/', verifyToken, isAdmin, listarPendentes);
router.get('/:id', verifyToken, isAdmin, detalheSolicitacao);
router.put('/:id', verifyToken, isAdmin, atualizarSolicitacao);
router.put('/:id/approve', verifyToken, isAdmin, aprovarSolicitacao);
router.put('/:id/reject', verifyToken, isAdmin, rejeitarSolicitacao);

export default router;
