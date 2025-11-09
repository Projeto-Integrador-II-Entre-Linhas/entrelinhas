import express from 'express';
import { addFavorito, removeFavorito, getFavoritos } from '../controllers/favoritoController.js';
import { verifyToken } from '../middlewares/authMiddleware.js';

const router = express.Router();

router.post('/', verifyToken, addFavorito);
router.get('/', verifyToken, getFavoritos);
router.delete('/:id_fichamento', verifyToken, removeFavorito);

export default router;
