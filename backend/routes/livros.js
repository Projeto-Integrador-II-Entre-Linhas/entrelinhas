import express from 'express';
import { addLivroByISBN, getLivros, searchLivrosGoogle, getLivroDetalhes } from '../controllers/livroController.js';
import { verifyToken } from '../middlewares/authMiddleware.js';

const router = express.Router();
router.get('/', getLivros);
router.get('/search', searchLivrosGoogle);
router.get('/:id', getLivroDetalhes);
router.post('/isbn', verifyToken, addLivroByISBN);
export default router;
