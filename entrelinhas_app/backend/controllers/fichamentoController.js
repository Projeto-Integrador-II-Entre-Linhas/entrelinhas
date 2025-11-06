import pool from '../db.js';

// Criar/editar fichamento
export const upsertFichamento = async (req,res) => {
  const { id_fichamento, id_livro, introducao, espaco, personagens, narrativa, conclusao, visibilidade, data_inicio, data_fim, formato, frase_favorita, nota } = req.body;
  const id_usuario = req.user.id_usuario;

  try {
    if(id_fichamento){
      // Atualizar
      const result = await pool.query(
        `UPDATE fichamentos SET introducao=$1, espaco=$2, personagens=$3, narrativa=$4, conclusao=$5, visibilidade=$6, data_inicio=$7, data_fim=$8, formato=$9, frase_favorita=$10, nota=$11, data_atualizacao=NOW()
         WHERE id_fichamento=$12 AND id_usuario=$13 RETURNING *`,
        [introducao, espaco, personagens, narrativa, conclusao, visibilidade, data_inicio, data_fim, formato, frase_favorita, nota, id_fichamento, id_usuario]
      );
      res.json(result.rows[0]);
    } else {
      // Criar
      const result = await pool.query(
        `INSERT INTO fichamentos (id_usuario, id_livro, introducao, espaco, personagens, narrativa, conclusao, visibilidade, data_inicio, data_fim, formato, frase_favorita, nota)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13) RETURNING *`,
        [id_usuario, id_livro, introducao, espaco, personagens, narrativa, conclusao, visibilidade, data_inicio, data_fim, formato, frase_favorita, nota]
      );
      res.json(result.rows[0]);
    }
  } catch(err){
    console.error(err);
    res.status(500).json({ error:'Erro ao salvar fichamento' });
  }
};

// Listar fichamentos públicos
export const getFichamentosPublicos = async (req,res) => {
  try{
    const result = await pool.query('SELECT * FROM fichamentos WHERE visibilidade=\'PUBLICO\'');
    res.json(result.rows);
  } catch(err){
    console.error(err);
    res.status(500).json({ error:'Erro ao listar fichamentos' });
  }
};
