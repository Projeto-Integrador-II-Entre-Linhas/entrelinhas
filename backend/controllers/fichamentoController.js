// controllers/fichamentoController.js
import pool from '../db.js';

// --- RF07 / RN04: Criar ou editar fichamento (um por livro/usuário) ---
export const upsertFichamento = async (req, res) => {
  const { id_fichamento, id_livro, introducao, espaco, personagens, narrativa, conclusao, visibilidade,
    data_inicio, data_fim, formato, frase_favorita, nota } = req.body;
  const id_usuario = req.user.sub;

  try {
    const dup = await pool.query('SELECT 1 FROM fichamentos WHERE id_usuario=$1 AND id_livro=$2', [id_usuario, id_livro]);
    if (!id_fichamento && dup.rows.length > 0) {
      return res.status(400).json({ error: 'Você já possui um fichamento para este livro.' });
    }

    if (id_fichamento) {
      const sql = `UPDATE fichamentos SET introducao=$1, espaco=$2, personagens=$3, narrativa=$4, conclusao=$5,
        visibilidade=$6, data_inicio=$7, data_fim=$8, formato=$9, frase_favorita=$10, nota=$11, data_atualizacao=NOW()
        WHERE id_fichamento=$12 AND id_usuario=$13 RETURNING *`;
      const { rows } = await pool.query(sql, [introducao, espaco, personagens, narrativa, conclusao, visibilidade, data_inicio, data_fim, formato, frase_favorita, nota, id_fichamento, id_usuario]);
      return res.json(rows[0]);
    } else {
      const sql = `INSERT INTO fichamentos (id_usuario, id_livro, introducao, espaco, personagens, narrativa, conclusao,
        visibilidade, data_inicio, data_fim, formato, frase_favorita, nota)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13) RETURNING *`;
      const { rows } = await pool.query(sql, [id_usuario, id_livro, introducao, espaco, personagens, narrativa, conclusao,
        visibilidade, data_inicio, data_fim, formato, frase_favorita, nota]);
      return res.json(rows[0]);
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao salvar fichamento' });
  }
};

// -- buscar fichamentos públicos ---
export const getFichamentosPublicos = async (req, res) => {
  try {
    const { rows } = await pool.query(
      "SELECT * FROM fichamentos WHERE visibilidade='PUBLICO'"
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao buscar fichamentos públicos' });
  }
};
