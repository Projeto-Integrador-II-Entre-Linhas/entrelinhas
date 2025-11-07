import pool from '../db.js';

// Adicionar favorito
export const addFavorito = async (req, res) => {
  const { id_fichamento } = req.body;
  const id_usuario = req.user.sub;

  try {
    const existe = await pool.query(
      'SELECT 1 FROM favoritos WHERE id_usuario=$1 AND id_fichamento=$2',
      [id_usuario, id_fichamento]
    );
    if (existe.rows.length > 0) {
      return res.status(400).json({ error: 'Já favoritado' });
    }

    const result = await pool.query(
      'INSERT INTO favoritos (id_usuario, id_fichamento) VALUES ($1,$2) RETURNING *',
      [id_usuario, id_fichamento]
    );
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao favoritar' });
  }
};

// Listar favoritos do usuário com dados do fichamento e do livro
export const getFavoritos = async (req, res) => {
  const id_usuario = req.user.sub;
  try {
    const result = await pool.query(
      `SELECT
         f.id_favorito,
         fi.*,
         l.titulo,
         l.autor,
         l.capa_url
       FROM favoritos f
       JOIN fichamentos fi ON fi.id_fichamento = f.id_fichamento
       JOIN livros l ON l.id_livro = fi.id_livro
       WHERE f.id_usuario = $1
       ORDER BY fi.data_atualizacao DESC NULLS LAST, fi.data_criacao DESC`,
      [id_usuario]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao listar favoritos' });
  }
};
