import express from 'express';
import {
  addLivroByISBN,
  getLivros,
  searchLivrosGoogle,
  getLivroDetalhes,
  adminUpdateLivro,
  adminDeleteLivro,
  getGeneros
} from '../controllers/livroController.js';
import { verifyToken, isAdmin } from '../middlewares/authMiddleware.js';

const router = express.Router();

// Usuário comum
router.get('/', getLivros);
router.get('/search', searchLivrosGoogle);
router.get('/generos', getGeneros);
router.get('/:id', getLivroDetalhes);
router.post('/isbn', verifyToken, addLivroByISBN);

// Admin
router.put('/:id', verifyToken, isAdmin, adminUpdateLivro);
router.delete('/:id', verifyToken, isAdmin, adminDeleteLivro);

export default router;
