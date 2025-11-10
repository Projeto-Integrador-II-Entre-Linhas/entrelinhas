import express from 'express';
import {
  upsertFichamento,
  getMyFichamentos,
  getFichamentosPublicos,
  getFichamentoById,
  getMeuPorLivro,
  deleteFichamento
} from '../controllers/fichamentoController.js';
import { verifyToken, optionalAuth } from '../middlewares/authMiddleware.js';

const router = express.Router();

// Públicos (com filtros)
router.get('/publicos', getFichamentosPublicos);

// Meus fichamentos
router.get('/me', verifyToken, getMyFichamentos);

// Meu fichamento por livro (para edição)
router.get('/me/:idLivro', verifyToken, getMeuPorLivro);

// Detalhe por ID (público ou do próprio usuário)
router.get('/:id', optionalAuth, getFichamentoById);

// Criar/editar
router.post('/', verifyToken, upsertFichamento);

// Excluir o próprio fichamento
router.delete('/:id', verifyToken, deleteFichamento);

export default router;
