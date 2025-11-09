// controllers/dashboardController.js
import pool from '../db.js';

export const getDashboard = async (req, res) => {
  const id = req.user.sub;

  try {
    // 👤 Dados do usuário logado
    const me = await pool.query(
      `SELECT id_usuario, nome, usuario, email, avatar, perfil, generos_preferidos
         FROM usuarios
        WHERE id_usuario = $1`,
      [id]
    );

    // ⭐ Fichamentos favoritados
    const favoritos = await pool.query(
      `SELECT fi.id_fichamento, fi.nota, l.titulo, l.autor, l.capa_url
         FROM favoritos f
         JOIN fichamentos fi ON fi.id_fichamento = f.id_fichamento
         JOIN livros l ON l.id_livro = fi.id_livro
        WHERE f.id_usuario = $1
        ORDER BY fi.data_atualizacao DESC NULLS LAST, fi.data_criacao DESC
        LIMIT 6`,
      [id]
    );

    // 📚 Meus fichamentos
    const meus = await pool.query(
      `SELECT fi.id_fichamento, fi.introducao, fi.nota, fi.visibilidade,
              l.titulo, l.autor, l.capa_url
         FROM fichamentos fi
         JOIN livros l ON l.id_livro = fi.id_livro
        WHERE fi.id_usuario = $1
        ORDER BY fi.data_atualizacao DESC NULLS LAST, fi.data_criacao DESC
        LIMIT 6`,
      [id]
    );

    // 📬 Solicitações de livros feitas pelo usuário
    const solicit = await pool.query(
      `SELECT id_solicitacao, titulo, autor, status, data_solicitacao
         FROM solicitacoes_livros
        WHERE id_usuario = $1
        ORDER BY data_solicitacao DESC
        LIMIT 6`,
      [id]
    );

    // 🔮 Recomendações baseadas nos gêneros dos favoritos e fichamentos
    const rec = await pool.query(
      `WITH base AS (
         SELECT DISTINCT lg.id_genero
           FROM favoritos f
           JOIN fichamentos fi ON fi.id_fichamento = f.id_fichamento
           JOIN livro_genero lg ON lg.id_livro = fi.id_livro
          WHERE f.id_usuario = $1
         UNION
         SELECT DISTINCT lg.id_genero
           FROM fichamentos fi
           JOIN livro_genero lg ON lg.id_livro = fi.id_livro
          WHERE fi.id_usuario = $1
       )
       SELECT l.id_livro, l.titulo, l.autor, l.capa_url, l.ano_publicacao
         FROM livro_genero lg
         JOIN base b ON b.id_genero = lg.id_genero
         JOIN livros l ON l.id_livro = lg.id_livro
        WHERE l.status = 'APROVADO'
        GROUP BY l.id_livro, l.titulo, l.autor, l.capa_url, l.ano_publicacao
        ORDER BY l.ano_publicacao DESC NULLS LAST
        LIMIT 12`,
      [id]
    );

    // ✅ Resposta unificada
    res.json({
      user: me.rows[0],
      favoritos: favoritos.rows,
      meus_fichamentos: meus.rows,
      solicitacoes: solicit.rows,
      recomendados: rec.rows,
    });
  } catch (e) {
    console.error('DASHBOARD:', e);
    res.status(500).json({ error: 'Erro ao montar dashboard' });
  }
};
