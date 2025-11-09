import pool from '../db.js';

export const addFavorito = async (req, res) => {
  const { id_fichamento } = req.body;
  const id_usuario = req.user.sub;

  try {
    const existe = await pool.query(
      'SELECT 1 FROM favoritos WHERE id_usuario=$1 AND id_fichamento=$2',
      [id_usuario, id_fichamento]
    );
    if (existe.rows.length > 0) return res.status(400).json({ error: 'Já favoritado' });

    const result = await pool.query(
      'INSERT INTO favoritos (id_usuario, id_fichamento) VALUES ($1,$2) RETURNING *',
      [id_usuario, id_fichamento]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Erro ao favoritar:', err);
    res.status(500).json({ error: 'Erro ao favoritar' });
  }
};

export const removeFavorito = async (req, res) => {
  const id_usuario = req.user.sub;
  const { id_fichamento } = req.params;

  try {
    const result = await pool.query(
      'DELETE FROM favoritos WHERE id_usuario=$1 AND id_fichamento=$2 RETURNING *',
      [id_usuario, id_fichamento]
    );
    if (result.rowCount === 0) return res.status(404).json({ error: 'Favorito não encontrado' });
    res.json({ message: 'Favorito removido com sucesso' });
  } catch (err) {
    console.error('Erro ao remover favorito:', err);
    res.status(500).json({ error: 'Erro ao remover favorito' });
  }
};

export const getFavoritos = async (req, res) => {
  const id_usuario = req.user.sub;
  try {
    const result = await pool.query(
      `SELECT f.id_favorito,
              fi.id_fichamento,
              fi.introducao, fi.nota, fi.visibilidade, fi.data_criacao,
              l.titulo, l.autor, l.capa AS capa_url
         FROM favoritos f
         JOIN fichamentos fi ON fi.id_fichamento = f.id_fichamento
         JOIN livros l ON l.id_livro = fi.id_livro
        WHERE f.id_usuario = $1
        ORDER BY fi.data_atualizacao DESC NULLS LAST, fi.data_criacao DESC`,
      [id_usuario]
    );
    res.json(result.rows);
  } catch (err) {
    console.error('Erro ao listar favoritos:', err);
    res.status(500).json({ error: 'Erro ao listar favoritos' });
  }
};
