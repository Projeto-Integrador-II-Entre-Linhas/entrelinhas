// routes/fichamentos.js
import express from 'express';
import {
  upsertFichamento,
  getFichamentosPublicos,
  getFichamentosDoUsuario,
  getMeuFichamentoPorLivro
} from '../controllers/fichamentoController.js';
import { verifyToken } from '../middlewares/authMiddleware.js';

const router = express.Router();

// RF08 - públicos
router.get('/publicos', getFichamentosPublicos);

// RF04 - meus fichamentos
router.get('/', verifyToken, getFichamentosDoUsuario);

// RF07 - obter meu fichamento por livro (para pré-carregar a edição)
router.get('/me/:id_livro', verifyToken, getMeuFichamentoPorLivro);

// RF07 - criar/editar (upsert)
router.post('/', verifyToken, upsertFichamento);

export default router;
