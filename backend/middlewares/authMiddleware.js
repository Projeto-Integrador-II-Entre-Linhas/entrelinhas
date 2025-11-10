import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
dotenv.config();

const SECRET = process.env.JWT_SECRET || 'dev-secret';

export const verifyToken = (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1];
  if(!token) return res.status(401).json({ error:'Token não fornecido' });

  try {
    const decoded = jwt.verify(token, SECRET);
    req.user = decoded;
    next();
  } catch(err) {
    console.error('Token inválido:', err.message);
    return res.status(401).json({ error:'Token inválido' });
  }
};

export const optionalAuth = (req, _res, next) => {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return next();
  try {
    const decoded = jwt.verify(token, SECRET);
    req.user = decoded;
  } catch (e) { }
  next();
};

export const isAdmin = (req, res, next) => {
  if(req.user?.perfil !== 'ADMIN') return res.status(403).json({ error:'Acesso negado' });
  next();
};
