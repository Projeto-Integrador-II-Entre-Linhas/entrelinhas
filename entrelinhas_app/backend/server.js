import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/auth.js';
import livroRoutes from './routes/livros.js';
import fichamentoRoutes from './routes/fichamentos.js';
import favoritoRoutes from './routes/favoritos.js';

dotenv.config();
const app = express();

// Middlewares
app.use(cors({ origin: '*', methods: ['GET','POST','PUT','DELETE','OPTIONS'] }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Health
app.get('/', (_req, res) => res.send('🚀 Backend EntreLinhas rodando'));
app.get('/api/health', (_req, res) => res.json({ ok: true, time: new Date().toISOString() }));

// Rotas
app.use('/api/auth', authRoutes);
app.use('/api/livros', livroRoutes);
app.use('/api/fichamentos', fichamentoRoutes);
app.use('/api/favoritos', favoritoRoutes);

// Handler global de erros (mostra o erro real)
app.use((err, _req, res, _next) => {
  console.error('💥 ERRO:', err);
  res.status(err.status || 500).json({
    error: err.publicMessage || err.message || 'Erro interno no servidor',
    code: err.code,
    detail: err.detail,
  });
});

// Start
const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => console.log(`✅ Servidor rodando na porta ${PORT}`));
