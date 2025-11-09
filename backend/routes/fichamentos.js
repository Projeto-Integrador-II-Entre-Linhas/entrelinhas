import express from 'express';
import {
  upsertFichamento,
  getMyFichamentos,
  getFichamentosPublicos,
  getFichamentoById
} from '../controllers/fichamentoController.js';
import { verifyToken } from '../middlewares/authMiddleware.js';

const router = express.Router();

// RF08/RF09: públicos (com filtros)
router.get('/publicos', getFichamentosPublicos);

// RF07: meus fichamentos
router.get('/me', verifyToken, getMyFichamentos);

// RF12/RF08: detalhe
router.get('/:id', verifyToken, getFichamentoById);

// RF07: criar/editar
router.post('/', verifyToken, upsertFichamento);

export default router;
