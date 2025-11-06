import express from 'express';
import { addFavorito, getFavoritos } from '../controllers/favoritoController.js';
import { verifyToken } from '../middlewares/authMiddleware.js';

const router = express.Router();

router.post('/', verifyToken, addFavorito);
router.get('/', verifyToken, getFavoritos);

export default router;
