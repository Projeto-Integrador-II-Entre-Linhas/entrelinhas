import pool from '../db.js';

export const addFavorito = async (req,res) => {
  const { id_fichamento } = req.body;
  const id_usuario = req.user.id_usuario;

  try {
    const existe = await pool.query('SELECT * FROM favoritos WHERE id_usuario=$1 AND id_fichamento=$2', [id_usuario, id_fichamento]);
    if(existe.rows.length > 0) return res.status(400).json({ error:'Já favoritado' });

    const result = await pool.query('INSERT INTO favoritos (id_usuario, id_fichamento) VALUES ($1,$2) RETURNING *', [id_usuario, id_fichamento]);
    res.json(result.rows[0]);
  } catch(err){
    console.error(err);
    res.status(500).json({ error:'Erro ao favoritar' });
  }
};

export const getFavoritos = async (req,res) => {
  const id_usuario = req.user.id_usuario;
  try {
    const result = await pool.query(
      `SELECT f.*, fi.titulo, fi.autor 
       FROM favoritos f 
       JOIN fichamentos fi ON f.id_fichamento = fi.id_fichamento 
       WHERE f.id_usuario=$1`,
      [id_usuario]
    );
    res.json(result.rows);
  } catch(err){
    console.error(err);
    res.status(500).json({ error:'Erro ao listar favoritos' });
  }
};
