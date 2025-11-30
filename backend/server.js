import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import morgan from 'morgan';

import authRoutes from './routes/auth.js';
import userRoutes from './routes/users.js';
import livroRoutes from './routes/livros.js';
import fichamentoRoutes from './routes/fichamentos.js';
import favoritoRoutes from './routes/favoritos.js';
import solicitacaoRoutes from './routes/solicitacoes.js';
import dashboardRoutes from './routes/dashboard.js';

import path from 'path';
import { fileURLToPath } from 'url';

dotenv.config();

const app = express();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);


app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static('uploads'));
app.use(morgan('dev'));

// Rotas 
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/livros', livroRoutes);
app.use('/api/fichamentos', fichamentoRoutes);
app.use('/api/favoritos', favoritoRoutes);
app.use('/api/solicitacoes', solicitacaoRoutes);
app.use('/api/dashboard', dashboardRoutes);

// Servir arquivos estáticos do Flutter Web
app.use(express.static(path.join(__dirname, 'public')));

// Qualquer rota que não seja /api → devolver index.html do Flutter
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});


const PORT = process.env.PORT || 3000;

app.listen(PORT, '0.0.0.0', () =>
  console.log(`Servidor EntreLinhas rodando na porta ${PORT}`)
);
