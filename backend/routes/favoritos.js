import express from 'express';
import { verifyToken } from '../middlewares/authMiddleware.js';
import {
  addFavorito,
  removeFavorito,
  getFavoritos,
  isFavorito,
  toggleFavorito
} from '../controllers/favoritoController.js';

const router = express.Router();

// Adiciona favorito 
router.post('/', verifyToken, addFavorito);

// Remove favorito
router.delete('/:id_fichamento', verifyToken, removeFavorito);

// Lista todos os favoritos do usuário
router.get('/', verifyToken, getFavoritos);

// Verifica se um fichamento é favorito
router.get('/:id_fichamento', verifyToken, isFavorito);

// Alterna (favorita/desfavorita)
router.post('/:id_fichamento', verifyToken, toggleFavorito);

export default router;
