// routes/users.js
import express from 'express';
import { verifyToken, isAdmin } from '../middlewares/authMiddleware.js';
import { listarUsuarios, alterarStatus, excluirUsuario, atualizarPerfil } from '../controllers/userController.js';
import { uploadAvatar } from '../middlewares/uploadMiddleware.js';

const router = express.Router();

// RF05: Administração
router.get('/', verifyToken, isAdmin, listarUsuarios);
router.put('/:id/status', verifyToken, isAdmin, alterarStatus);
router.delete('/:id', verifyToken, isAdmin, excluirUsuario);

// RF11: Atualizar perfil
router.put('/me', verifyToken, uploadAvatar.single('avatar'), atualizarPerfil);

export default router;
