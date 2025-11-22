import pool from '../db.js';

export const getDashboard = async (req, res) => {
  const id = req.user.sub;

  try {
    // Dados do usuário logado
    const me = await pool.query(
      `SELECT id_usuario, nome, usuario, email, avatar, perfil, generos_preferidos
         FROM usuarios
        WHERE id_usuario = $1`,
      [id]
    );

    // Fichamentos favoritados
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

    // Meus fichamentos
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

    // Fichamentos públicos (de outros usuários)
    const publicos = await pool.query(
      `SELECT fi.id_fichamento, fi.introducao, fi.nota, fi.visibilidade,
              l.titulo, l.autor, l.capa_url, u.nome AS usuario
         FROM fichamentos fi
         JOIN livros l ON l.id_livro = fi.id_livro
         JOIN usuarios u ON u.id_usuario = fi.id_usuario
        WHERE fi.visibilidade = 'PUBLICO'
        ORDER BY fi.data_atualizacao DESC NULLS LAST, fi.data_criacao DESC
        LIMIT 12`
    );

    // Todas as solicitações (não só do usuário)
    const solicit = await pool.query(
      `SELECT s.id_solicitacao, s.titulo, s.autor, s.status, s.data_solicitacao, u.nome AS usuario
         FROM solicitacoes_livros s
         JOIN usuarios u ON u.id_usuario = s.id_usuario
        ORDER BY s.data_solicitacao DESC
        LIMIT 10`
    );

    // Recomendações baseadas nos gêneros
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

    const baseUrl = process.env.BASE_URL || 'http://172.16.40.245:3000';
    const fixUrls = (arr) => {
      return arr.map(item => {
        if (item.capa_url && !item.capa_url.startsWith('http')) {
          item.capa_url = `${baseUrl}${item.capa_url}`;
        }
        return item;
      });
    };

    res.json({
      user: me.rows[0],
      favoritos: fixUrls(favoritos.rows),
      meus_fichamentos: fixUrls(meus.rows),
      fichamentos_publicos: fixUrls(publicos.rows),
      solicitacoes: solicit.rows,
      recomendados: fixUrls(rec.rows),
    });
  } catch (e) {
    console.error('DASHBOARD:', e);
    res.status(500).json({ error: 'Erro ao montar dashboard' });
  }
};
