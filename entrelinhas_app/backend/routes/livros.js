import express from 'express';
import { addLivroByISBN, getLivros } from '../controllers/livroController.js';
import { verifyToken } from '../middlewares/authMiddleware.js';

const router = express.Router();

router.get('/', getLivros);
router.post('/isbn', verifyToken, addLivroByISBN);

export default router;
