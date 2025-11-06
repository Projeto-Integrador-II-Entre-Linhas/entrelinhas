import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
dotenv.config();

export const verifyToken = (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1];
  if(!token) return res.status(401).json({ error:'Token não fornecido' });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // id_usuario e perfil
    next();
  } catch(err) {
    return res.status(401).json({ error:'Token inválido' });
  }
};

export const isAdmin = (req, res, next) => {
  if(req.user.perfil !== 'ADMIN') return res.status(403).json({ error:'Acesso negado' });
  next();
};
