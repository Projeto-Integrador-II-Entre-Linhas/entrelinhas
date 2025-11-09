// controllers/solicitacaoController.js
import pool from '../db.js';
import { ensureLivroGeneros } from '../utils/genres.js';

// -------- Usuário cria solicitação COMPLETA (campos obrigatórios do seu BD) --------
export const solicitarLivro = async (req, res) => {
  const id_usuario = req.user.sub;
  const {
    titulo, autor, ano_publicacao, editora,
    isbn, descricao, idioma, num_paginas, capa_url, generos
  } = req.body;

  if (!titulo || !autor || !isbn || !ano_publicacao || !editora) {
    return res.status(400).json({ error: 'Campos obrigatórios: titulo, autor, isbn, ano_publicacao, editora' });
  }

  // cria rascunho de livro (status PENDENTE)
  const livro = await pool.query(
    `INSERT INTO livros (titulo, autor, capa, isbn, ano_publicacao, editora, num_paginas, descricao, idioma, status)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,'PENDENTE')
     RETURNING *`,
    [titulo, autor, capa_url || null, isbn, ano_publicacao, editora, num_paginas || null, descricao || null, idioma || null]
  );

  // vincula solicitação
  const solicit = await pool.query(
    `INSERT INTO solicitacoes_livros (id_usuario, id_livro, titulo, autor, ano_publicacao, editora, isbn, descricao, idioma, num_paginas, status)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'PENDENTE')
     RETURNING *`,
    [id_usuario, livro.rows[0].id_livro, titulo, autor, ano_publicacao, editora, isbn, descricao || null, idioma || null, num_paginas || null]
  );

  // salva gêneros provisórios
  if (Array.isArray(generos) && generos.length) {
    await ensureLivroGeneros(livro.rows[0].id_livro, generos);
  }

  res.status(201).json({ success: true, solicitacao: solicit.rows[0] });
};

// -------- Usuário lista suas solicitações --------
export const minhasSolicitacoes = async (req, res) => {
  const id_usuario = req.user.sub;
  const { rows } = await pool.query(
    `SELECT s.*, l.titulo as livro_titulo, l.status as status_livro
       FROM solicitacoes_livros s
       LEFT JOIN livros l ON l.id_livro = s.id_livro
      WHERE s.id_usuario=$1
      ORDER BY s.data_solicitacao DESC`, [id_usuario]
  );
  res.json(rows);
};

// -------- Admin: listar pendentes --------
export const listarPendentes = async (_req, res) => {
  const { rows } = await pool.query(
    `SELECT s.*, u.nome as usuario_nome, l.*
       FROM solicitacoes_livros s
       JOIN usuarios u ON u.id_usuario=s.id_usuario
       JOIN livros l ON l.id_livro=s.id_livro
      WHERE s.status='PENDENTE'
      ORDER BY s.data_solicitacao DESC`
  );
  res.json(rows);
};

// -------- Admin: aprovar solicitação -> livro APROVADO --------
export const aprovarSolicitacao = async (req, res) => {
  const { id } = req.params;

  // Pega solicitação + livro associado
  const { rows } = await pool.query(
    `SELECT s.*, l.id_livro FROM solicitacoes_livros s
      JOIN livros l ON l.id_livro=s.id_livro
     WHERE s.id_solicitacao=$1`, [id]
  );
  if (!rows.length) return res.status(404).json({ error:'Solicitação não encontrada' });

  const solic = rows[0];
  await pool.query(`UPDATE livros SET status='APROVADO' WHERE id_livro=$1`, [solic.id_livro]);
  await pool.query(`UPDATE solicitacoes_livros SET status='APROVADO' WHERE id_solicitacao=$1`, [id]);

  res.json({ success: true, message: 'Solicitação aprovada e livro aprovado' });
};

// -------- Admin: rejeitar, opcionalmente com motivo --------
export const rejeitarSolicitacao = async (req, res) => {
  const { id } = req.params;
  const { motivo } = req.body;

  const { rows } = await pool.query(
    `SELECT s.*, l.id_livro FROM solicitacoes_livros s
      JOIN livros l ON l.id_livro=s.id_livro
     WHERE s.id_solicitacao=$1`, [id]
  );
  if (!rows.length) return res.status(404).json({ error:'Solicitação não encontrada' });

  const solic = rows[0];
  await pool.query(`UPDATE livros SET status='REJEITADO', motivo_rejeicao=$1 WHERE id_livro=$2`, [motivo || null, solic.id_livro]);
  await pool.query(`UPDATE solicitacoes_livros SET status='REJEITADO' WHERE id_solicitacao=$1`, [id]);

  res.json({ success: true, message: 'Solicitação rejeitada' });
};
