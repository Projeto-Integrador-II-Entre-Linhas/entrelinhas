// middleware/uploadMiddleware.js
import multer from 'multer';
import path from 'path';
import mime from 'mime-types';
import fs from 'fs';

// --- RF11: Upload de avatar com validação --- //
const uploadDir = 'uploads/avatars';

// Cria a pasta, caso não exista
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    const ext = mime.extension(file.mimetype) || 'jpg';
    const unique = `${req.user?.sub || 'anon'}_${Date.now()}.${ext}`;
    cb(null, unique);
  },
});

const fileFilter = (req, file, cb) => {
  const allowed = [
    'image/jpeg',
    'image/png',
    'image/jpg',
    'image/webp',
    'image/gif',
    'image/heic',
  ];

  if (!allowed.includes(file.mimetype)) {
    console.error('❌ Tipo de arquivo rejeitado:', file.mimetype);
    return cb(new Error('Tipo de arquivo não permitido. Envie uma imagem válida (.jpg, .png, .webp, etc.)'));
  }

  cb(null, true);
};

export const uploadAvatar = multer({
  storage,
  limits: { fileSize: 2 * 1024 * 1024 }, // Máximo 2MB
  fileFilter,
});
