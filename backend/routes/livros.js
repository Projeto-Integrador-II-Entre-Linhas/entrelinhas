import express from 'express';
import { addLivroByISBN, getLivros, searchLivrosGoogle } from '../controllers/livroController.js';
import { verifyToken } from '../middlewares/authMiddleware.js';

const router = express.Router();

// Buscar livros do banco interno
router.get('/', getLivros);

// Buscar livros da API do Google Books (por título ou ISBN)
router.get('/search', searchLivrosGoogle);

// Cadastrar livro no banco a partir do ISBN
router.post('/isbn', verifyToken, addLivroByISBN);

export default router;
