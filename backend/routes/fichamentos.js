import express from 'express';
import {
  upsertFichamento,
  getMyFichamentos,
  getFichamentosPublicos,
  getFichamentoById,
  getMeuPorLivro,
  deleteFichamento,
  getGeneros
} from '../controllers/fichamentoController.js';

import { verifyToken, optionalAuth } from '../middlewares/authMiddleware.js';

const router = express.Router();

//Listar gêneros para filtros
router.get('/generos', getGeneros);

//Públicos + filtragem por título/autor
router.get('/publicos', getFichamentosPublicos);

//Meus fichamentos
router.get('/me', verifyToken, getMyFichamentos);

//Fichamento do usuário por livro (para edição)
router.get('/me/:idLivro', verifyToken, getMeuPorLivro);

//Abrir detalhes (público ou do dono)
router.get('/:id', optionalAuth, getFichamentoById);

//Criar/editar fichamento
router.post('/', verifyToken, upsertFichamento);

//Excluir fichamento
router.delete('/:id', verifyToken, deleteFichamento);

export default router;
