// controllers/solicitacaoController.js
import pool from '../db.js';

// --- RF06 / RN07: Solicitação de novos livros (usuário comum) --- //
export const solicitarLivro = async (req, res) => {
  const id_usuario = req.user.sub;
  const { titulo, autor, editora, ano_publicacao } = req.body;
  if (!titulo || !autor) return res.status(400).json({ error: 'Título e autor são obrigatórios' });

  const result = await pool.query(
    'INSERT INTO solicitacoes_livros (id_usuario, data_solicitacao) VALUES ($1, NOW()) RETURNING *',
    [id_usuario]
  );

  res.status(201).json({ success: true, solicitacao: result.rows[0] });
};
