import pool from '../db.js';

// --- RF07 + RN04: Criar/editar fichamento (um por livro/usuário) ---
export const upsertFichamento = async (req, res) => {
  const {
    id_fichamento,
    id_livro,
    introducao,
    espaco,
    personagens,
    narrativa,
    conclusao,
    visibilidade,
    data_inicio,
    data_fim,
    formato,
    frase_favorita,
    nota
  } = req.body;

  const id_usuario = req.user.sub;

  if (!id_livro || !introducao || !data_inicio || !formato || nota == null) {
    return res.status(400).json({ error: 'Campos obrigatórios ausentes' });
  }

  try {
    // RN04 – apenas um fichamento por (usuario, livro)
    const dup = await pool.query(
      'SELECT 1 FROM fichamentos WHERE id_usuario=$1 AND id_livro=$2 AND ($3::INT IS NULL OR id_fichamento<>$3)',
      [id_usuario, id_livro, id_fichamento || null]
    );
    if (dup.rows.length > 0) {
      return res.status(400).json({ error: 'Você já possui um fichamento para este livro.' });
    }

    if (id_fichamento) {
      // RN06 – só o dono edita
      const owner = await pool.query(
        'SELECT 1 FROM fichamentos WHERE id_fichamento=$1 AND id_usuario=$2',
        [id_fichamento, id_usuario]
      );
      if (owner.rows.length === 0) {
        return res.status(403).json({ error: 'Você não pode editar este fichamento.' });
      }

      const sql = `
        UPDATE fichamentos
           SET introducao=$1, espaco=$2, personagens=$3, narrativa=$4, conclusao=$5,
               visibilidade=$6, data_inicio=$7, data_fim=$8, formato=$9, frase_favorita=$10,
               nota=$11, data_atualizacao=NOW()
         WHERE id_fichamento=$12 AND id_usuario=$13
     RETURNING *`;
      const { rows } = await pool.query(sql, [
        introducao, espaco, personagens, narrativa, conclusao,
        visibilidade || 'PRIVADO', data_inicio, data_fim, formato,
        frase_favorita, nota, id_fichamento, id_usuario
      ]);
      return res.json(rows[0]);
    }

    const sql = `
      INSERT INTO fichamentos
        (id_usuario, id_livro, introducao, espaco, personagens, narrativa, conclusao,
         visibilidade, data_inicio, data_fim, formato, frase_favorita, nota)
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
      RETURNING *`;
    const { rows } = await pool.query(sql, [
      id_usuario, id_livro, introducao, espaco, personagens, narrativa, conclusao,
      visibilidade || 'PRIVADO', data_inicio, data_fim, formato, frase_favorita, nota
    ]);
    return res.status(201).json(rows[0]);
  } catch (err) {
    console.error('UPSERT FICHAMENTO:', err);
    res.status(500).json({ error: 'Erro ao salvar fichamento' });
  }
};

// --- RF07: listar fichamentos do usuário (para RF04 “meus fichamentos”) ---
export const getMyFichamentos = async (req, res) => {
  const id_usuario = req.user.sub;
  try {
    const { rows } = await pool.query(
      `SELECT f.*, l.titulo, l.autor
         FROM fichamentos f
         JOIN livros l ON l.id_livro = f.id_livro
        WHERE f.id_usuario=$1
        ORDER BY f.data_atualizacao DESC NULLS LAST, f.data_criacao DESC`,
      [id_usuario]
    );
    res.json(rows);
  } catch (err) {
    console.error('MY FICHAMENTOS:', err);
    res.status(500).json({ error: 'Erro ao listar fichamentos' });
  }
};

// --- RF08/RF09: listar públicos com filtros (autor, título, gênero) ---
export const getFichamentosPublicos = async (req, res) => {
  const { autor, titulo, genero } = req.query;
  try {
    let sql = `
      SELECT f.*, l.titulo, l.autor
        FROM fichamentos f
        JOIN livros l ON l.id_livro = f.id_livro
       WHERE f.visibilidade='PUBLICO'`;
    const params = [];

    if (autor) {
      params.push(`%${autor}%`);
      sql += ` AND l.autor ILIKE $${params.length}`;
    }
    if (titulo) {
      params.push(`%${titulo}%`);
      sql += ` AND l.titulo ILIKE $${params.length}`;
    }
    if (genero) {
      params.push(`%${genero}%`);
      sql += ` AND l.id_livro IN (
                 SELECT lg.id_livro
                   FROM livro_genero lg
                   JOIN generos g ON g.id_genero = lg.id_genero
                  WHERE g.nome ILIKE $${params.length}
               )`;
    }

    sql += ` ORDER BY f.data_atualizacao DESC NULLS LAST, f.data_criacao DESC`;

    const { rows } = await pool.query(sql, params);
    res.json(rows);
  } catch (err) {
    console.error('PUBLICOS:', err);
    res.status(500).json({ error: 'Erro ao buscar fichamentos públicos' });
  }
};

// --- RF12/RF08: detalhe de um fichamento (público ou do próprio usuário) ---
export const getFichamentoById = async (req, res) => {
  const { id } = req.params;
  const me = req.user?.sub || null;

  try {
    const { rows } = await pool.query(
      'SELECT * FROM fichamentos WHERE id_fichamento=$1',
      [id]
    );
    if (rows.length === 0) return res.status(404).json({ error: 'Fichamento não encontrado' });

    const f = rows[0];
    if (f.visibilidade !== 'PUBLICO' && f.id_usuario !== me) {
      return res.status(403).json({ error: 'Este fichamento é privado' });
    }
    res.json(f);
  } catch (err) {
    console.error('DETALHE FICHAMENTO:', err);
    res.status(500).json({ error: 'Erro ao buscar fichamento' });
  }
};
