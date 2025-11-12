import pool from '../db.js';
import { ensureLivroGeneros } from '../utils/genres.js';

// ==========================================================
// USUÁRIO: solicitar novo livro
// ==========================================================
export const solicitarLivro = async (req, res) => {
  const id_usuario = req.user.sub;
  const {
    titulo, autor, ano_publicacao, editora,
    isbn, descricao, idioma, num_paginas, capa_url, generos
  } = req.body;

  if (!titulo || !autor || !isbn || !ano_publicacao || !editora) {
    return res.status(400).json({ error: 'Campos obrigatórios: titulo, autor, isbn, ano_publicacao, editora' });
  }

  try {
    // Cria o registro do livro pendente
    const livro = await pool.query(
      `INSERT INTO livros (titulo, autor, capa_url, isbn, ano_publicacao, editora, num_paginas, descricao, idioma, status)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,'PENDENTE')
       RETURNING *`,
      [titulo, autor, capa_url || null, isbn, ano_publicacao, editora, num_paginas || null, descricao || null, idioma || null]
    );

    // Cria a solicitação vinculada ao livro
    const solicit = await pool.query(
      `INSERT INTO solicitacoes_livros (id_usuario, id_livro, titulo, autor, ano_publicacao, editora, isbn, descricao, idioma, num_paginas, status)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,'PENDENTE')
       RETURNING *`,
      [id_usuario, livro.rows[0].id_livro, titulo, autor, ano_publicacao, editora, isbn, descricao || null, idioma || null, num_paginas || null]
    );

    if (Array.isArray(generos) && generos.length) {
      await ensureLivroGeneros(livro.rows[0].id_livro, generos);
    }

    res.status(201).json({ success: true, solicitacao: solicit.rows[0] });
  } catch (err) {
    console.error('SOLICITAR LIVRO:', err);
    res.status(500).json({ error: 'Erro ao solicitar livro' });
  }
};

// ==========================================================
// USUÁRIO: listar minhas solicitações
// ==========================================================
export const minhasSolicitacoes = async (req, res) => {
  const id_usuario = req.user.sub;
  try {
    const { rows } = await pool.query(
      `SELECT id_solicitacao, titulo, autor, status, data_solicitacao, motivo_rejeicao
         FROM solicitacoes_livros
        WHERE id_usuario=$1
        ORDER BY data_solicitacao DESC`,
      [id_usuario]
    );
    res.json(rows);
  } catch (err) {
    console.error('MINHAS SOLICITAÇÕES:', err);
    res.status(500).json({ error: 'Erro ao listar solicitações' });
  }
};

// ==========================================================
// ADMIN: listar solicitações pendentes
// ==========================================================
export const listarPendentes = async (_req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT s.*, u.nome AS usuario_nome, u.email
         FROM solicitacoes_livros s
         JOIN usuarios u ON u.id_usuario = s.id_usuario
        WHERE s.status='PENDENTE'
        ORDER BY s.data_solicitacao DESC`
    );
    res.json(rows);
  } catch (err) {
    console.error('LISTAR PENDENTES:', err);
    res.status(500).json({ error: 'Erro ao listar solicitações pendentes' });
  }
};

// ==========================================================
// ADMIN: aprovar solicitação (livro passa a APROVADO)
// ==========================================================
export const aprovarSolicitacao = async (req, res) => {
  const { id } = req.params;
  try {
    const solicit = await pool.query(
      `UPDATE solicitacoes_livros
          SET status='APROVADO', data_resposta=NOW()
        WHERE id_solicitacao=$1
        RETURNING *`,
      [id]
    );

    if (!solicit.rows.length) {
      return res.status(404).json({ error: 'Solicitação não encontrada' });
    }

    const s = solicit.rows[0];
    await pool.query('UPDATE livros SET status=$1 WHERE id_livro=$2', ['APROVADO', s.id_livro]);

    res.json({ success: true, message: 'Solicitação aprovada', solicitacao: s });
  } catch (err) {
    console.error('APROVAR SOLICITAÇÃO:', err);
    res.status(500).json({ error: 'Erro ao aprovar solicitação' });
  }
};

// ==========================================================
// ADMIN: rejeitar solicitação com motivo
// ==========================================================
export const rejeitarSolicitacao = async (req, res) => {
  const { id } = req.params;
  const { motivo } = req.body;

  try {
    const solicit = await pool.query(
      `UPDATE solicitacoes_livros
          SET status='REJEITADO', motivo_rejeicao=$2, data_resposta=NOW()
        WHERE id_solicitacao=$1
        RETURNING *`,
      [id, motivo || null]
    );

    if (!solicit.rows.length) {
      return res.status(404).json({ error: 'Solicitação não encontrada' });
    }

    // Livro associado volta a "INATIVO" ou permanece PENDENTE, conforme necessidade
    await pool.query('UPDATE livros SET status=$1 WHERE id_livro=$2', ['INATIVO', solicit.rows[0].id_livro]);

    res.json({ success: true, message: 'Solicitação rejeitada', solicitacao: solicit.rows[0] });
  } catch (err) {
    console.error('REJEITAR SOLICITAÇÃO:', err);
    res.status(500).json({ error: 'Erro ao rejeitar solicitação' });
  }
};

// ADMIN: obter detalhes de uma solicitação
export const detalheSolicitacao = async (req, res) => {
  const { id } = req.params;
  try {
    const { rows } = await pool.query(
      `SELECT s.*, u.nome AS usuario_nome, u.email
         FROM solicitacoes_livros s
         JOIN usuarios u ON u.id_usuario = s.id_usuario
        WHERE s.id_solicitacao=$1`,
      [id]
    );
    if (!rows.length) return res.status(404).json({ error: 'Solicitação não encontrada' });
    res.json(rows[0]);
  } catch (err) {
    console.error('DETALHE SOLICITAÇÃO:', err);
    res.status(500).json({ error: 'Erro ao buscar solicitação' });
  }
};

// ADMIN: atualizar dados da solicitação (editar antes de aprovar/rejeitar)
export const atualizarSolicitacao = async (req, res) => {
  const { id } = req.params;
  const {
    titulo, autor, ano_publicacao, editora, isbn,
    descricao, idioma, num_paginas, capa_url
  } = req.body;

  try {
    const updates = [];
    const values = [];
    let i = 1;

    const add = (col, val) => { if (val !== undefined) { updates.push(`${col}=$${i++}`); values.push(val); } };

    add('titulo', titulo);
    add('autor', autor);
    add('ano_publicacao', ano_publicacao);
    add('editora', editora);
    add('isbn', isbn);
    add('descricao', descricao);
    add('idioma', idioma);
    add('num_paginas', num_paginas);
    add('capa_url', capa_url);

    if (!updates.length) return res.status(400).json({ error: 'Nada para atualizar' });
    values.push(id);

    const { rows } = await pool.query(
      `UPDATE solicitacoes_livros SET ${updates.join(', ')} WHERE id_solicitacao=$${i} RETURNING *`,
      values
    );
    if (!rows.length) return res.status(404).json({ error: 'Solicitação não encontrada' });
    res.json({ success: true, solicitacao: rows[0] });
  } catch (err) {
    console.error('ATUALIZAR SOLICITAÇÃO:', err);
    res.status(500).json({ error: 'Erro ao atualizar solicitação' });
  }
};
