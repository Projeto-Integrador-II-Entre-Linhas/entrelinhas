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

dotenv.config();
const app = express();

dotenv.config();
console.log('EMAIL_USER:', process.env.EMAIL_USER);

// === Middlewares ===
app.use(cors({ origin: '*', methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'] }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/uploads', express.static('uploads'));
app.use(morgan('dev'));

// === Rotas ===
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/livros', livroRoutes);
app.use('/api/fichamentos', fichamentoRoutes);
app.use('/api/favoritos', favoritoRoutes);
app.use('/api/solicitacoes', solicitacaoRoutes);
app.use('/api/dashboard', dashboardRoutes);

// === Health check ===
app.get('/', (_req, res) => res.send('Backend EntreLinhas rodando'));
app.get('/api/health', (_req, res) => res.json({ ok: true, time: new Date().toISOString() }));

// === Handler global de erros ===
app.use((err, _req, res, _next) => {
  console.error('ERRO:', err);
  res.status(err.status || 500).json({
    error: err.publicMessage || err.message || 'Erro interno no servidor',
    code: err.code,
    detail: err.detail,
  });
});

// === Start do servidor ===
const PORT = process.env.PORT || 3000;
//app.listen(PORT, 'localhost', () => console.log(`Servidor rodando na porta ${PORT}`));
app.listen(PORT, '0.0.0.0', () => console.log(`Servidor rodando na porta ${PORT}`));


