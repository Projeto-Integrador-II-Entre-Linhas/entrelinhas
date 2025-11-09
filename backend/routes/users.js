import express from 'express';
import { verifyToken, isAdmin } from '../middlewares/authMiddleware.js';
import { me, listarUsuarios, alterarStatus, excluirUsuario, atualizarPerfil, setPerfil } from '../controllers/userController.js';
import { uploadAvatar } from '../middlewares/uploadMiddleware.js';

const router = express.Router();

// Admin
router.get('/', verifyToken, isAdmin, listarUsuarios);
router.put('/:id/status', verifyToken, isAdmin, alterarStatus);
router.put('/:id/perfil', verifyToken, isAdmin, setPerfil);
router.delete('/:id', verifyToken, isAdmin, excluirUsuario);

// Perfil
router.get('/me', verifyToken, me);
router.put('/me', verifyToken, uploadAvatar.single('avatar'), atualizarPerfil);

export default router;
