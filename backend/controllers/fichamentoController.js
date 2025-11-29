import pool from '../db.js';

// --- Criar/editar fichamento (um por livro/usuário) ---
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
    nota,
    generos
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

    let rows;

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
      ({ rows } = await pool.query(sql, [
        introducao, espaco, personagens, narrativa, conclusao,
        visibilidade || 'PRIVADO', data_inicio, data_fim, formato,
        frase_favorita, nota, id_fichamento, id_usuario
      ]));
    } else {
      const sql = `
        INSERT INTO fichamentos
          (id_usuario, id_livro, introducao, espaco, personagens, narrativa, conclusao,
           visibilidade, data_inicio, data_fim, formato, frase_favorita, nota)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
        RETURNING *`;
      ({ rows } = await pool.query(sql, [
        id_usuario, id_livro, introducao, espaco, personagens, narrativa, conclusao,
        visibilidade || 'PRIVADO', data_inicio, data_fim, formato, frase_favorita, nota
      ]));
    }

    const fichamentoId = rows[0].id_fichamento;

    // --- Vincular gêneros, se enviados ---
    if (generos && Array.isArray(generos) && generos.length > 0) {
      const { rows: generosRows } = await pool.query(
        `SELECT id_genero FROM generos WHERE nome = ANY($1)`,
        [generos]
      );
      const idGeneros = generosRows.map(g => g.id_genero);
      await pool.query(`DELETE FROM fichamento_genero WHERE id_fichamento=$1`, [fichamentoId]);
      for (const idg of idGeneros) {
        await pool.query(
          `INSERT INTO fichamento_genero (id_fichamento, id_genero) VALUES ($1,$2)`,
          [fichamentoId, idg]
        );
      }
    }

    return res.status(id_fichamento ? 200 : 201).json(rows[0]);
  } catch (err) {
    console.error('UPSERT FICHAMENTO:', err);
    res.status(500).json({ error: 'Erro ao salvar fichamento' });
  }
};

// --- listar fichamentos do usuário ---
export const getMyFichamentos = async (req, res) => {
  const id_usuario = req.user.sub;
  try {
    const { rows } = await pool.query(
      `SELECT f.*, l.titulo, l.autor, l.capa_url
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

// --- obter meu fichamento por livro ---
export const getMeuPorLivro = async (req, res) => {
  const id_usuario = req.user.sub;
  const { idLivro } = req.params;
  try {
    const { rows } = await pool.query(
      `SELECT * FROM fichamentos WHERE id_usuario=$1 AND id_livro=$2 LIMIT 1`,
      [id_usuario, idLivro]
    );
    if (!rows.length) return res.status(404).json({ error: 'Nenhum fichamento seu para este livro' });
    res.json(rows[0]);
  } catch (err) {
    console.error('MEU POR LIVRO:', err);
    res.status(500).json({ error: 'Erro ao buscar seu fichamento' });
  }
};

// --- listar públicos ---
export const getFichamentosPublicos = async (req, res) => {
  const { autor, titulo, genero, q } = req.query;

  let sql = `
      SELECT f.id_fichamento, f.introducao, f.frase_favorita, f.nota,
             u.nome AS usuario_nome, 
             l.id_livro, l.titulo, l.autor, l.capa_url,
             COALESCE(
                (SELECT ARRAY_AGG(COALESCE(g.nome_pt,g.nome))
                 FROM livro_genero lg
                 JOIN generos g ON g.id_genero = lg.id_genero
                 WHERE lg.id_livro = l.id_livro),
              '{}') AS generos
      FROM fichamentos f
      JOIN livros l ON l.id_livro = f.id_livro
      JOIN usuarios u ON u.id_usuario = f.id_usuario
      WHERE f.visibilidade='PUBLICO'
  `;

  const params = [];

  if (q || titulo || autor) {
    const termo = q ?? titulo ?? autor;
    params.push(`%${termo}%`);
    sql += ` AND (l.titulo ILIKE $${params.length} OR l.autor ILIKE $${params.length})`;
  }

  if (genero) {
    const list = genero.split(",").map(s => s.trim());
    const ph = list.map((_,i)=>`$${params.length+i+1}`).join(",");
    sql += `
      AND l.id_livro IN (
        SELECT lg.id_livro FROM livro_genero lg
        JOIN generos g ON g.id_genero = lg.id_genero
        WHERE COALESCE(g.nome_pt,g.nome) IN (${ph})
      )`;
    params.push(...list);
  }

  sql+=` ORDER BY f.data_atualizacao DESC NULLS LAST, f.data_criacao DESC`;

  try{
    const {rows}=await pool.query(sql,params);
    res.json(rows);
  }catch(e){
    console.error("ERRO PUBLICOS:",e);
    res.status(500).json({error:"Falha ao buscar fichamentos"});
  }
};


// --- detalhe de um fichamento (público ou do próprio usuário) ---
export const getFichamentoById = async (req, res) => {
  const { id } = req.params;
  const me = req.user?.sub || null;

  try {
    const { rows } = await pool.query(
      `SELECT
          f.id_fichamento, f.id_usuario, f.id_livro,
          f.introducao, f.espaco, f.personagens, f.narrativa, f.conclusao,
          f.visibilidade, f.data_inicio, f.data_fim, f.formato,
          f.frase_favorita, f.nota, f.data_criacao, f.data_atualizacao,
          l.titulo, l.autor, l.capa_url, l.descricao,
          u.nome AS usuario_nome,

          /* gêneros do LIVRO -> traduzido */
          COALESCE(
            (SELECT ARRAY_AGG(COALESCE(g.nome_pt,g.nome) ORDER BY COALESCE(g.nome_pt,g.nome))
             FROM livro_genero lg
             JOIN generos g ON g.id_genero = lg.id_genero
             WHERE lg.id_livro = f.id_livro),
          '{}') AS generos_livro,

          /* gêneros ADICIONADOS no fichamento -> traduzido */
          COALESCE(
            (SELECT ARRAY_AGG(COALESCE(g.nome_pt,g.nome) ORDER BY COALESCE(g.nome_pt,g.nome))
             FROM fichamento_genero fg
             JOIN generos g ON g.id_genero = fg.id_genero
             WHERE fg.id_fichamento = f.id_fichamento),
          '{}') AS generos_fichamento

        FROM fichamentos f
        JOIN livros l ON l.id_livro = f.id_livro
        JOIN usuarios u ON u.id_usuario = f.id_usuario
       WHERE f.id_fichamento = $1`,
      [id]
    );

    if (!rows.length) return res.status(404).json({ error: 'Fichamento não encontrado' });

    const f = rows[0];

    if (f.visibilidade !== 'PUBLICO' && f.id_usuario !== me) {
      return res.status(403).json({ error: 'Este fichamento é privado' });
    }

    f.generos = [...new Set([...f.generos_livro, ...f.generos_fichamento])];
    delete f.generos_livro;
    delete f.generos_fichamento;

    res.json(f);

  } catch (err) {
    console.error('DETALHE FICHAMENTO:', err);
    res.status(500).json({ error: 'Erro ao buscar fichamento' });
  }
};


// --- excluir o próprio fichamento ---
export const deleteFichamento = async (req, res) => {
  const id_usuario = req.user.sub;
  const { id } = req.params;

  try {
    const own = await pool.query(
      `SELECT 1 FROM fichamentos WHERE id_fichamento=$1 AND id_usuario=$2`,
      [id, id_usuario]
    );
    if (!own.rows.length)
      return res.status(403).json({ error: 'Você não pode excluir este fichamento' });

    await pool.query(`DELETE FROM favoritos WHERE id_fichamento=$1`, [id]);
    await pool.query(`DELETE FROM fichamentos WHERE id_fichamento=$1`, [id]);

    res.json({ success: true, message: 'Fichamento excluído' });
  } catch (err) {
    console.error('DELETE FICHAMENTO:', err);
    res.status(500).json({ error: 'Erro ao excluir fichamento' });
  }
};

export const getGeneros = async (req, res) => {
  try {
    const { rows } = await pool.query(`
      SELECT id_genero, nome, nome_pt
      FROM generos
      ORDER BY nome_pt ASC NULLS LAST
    `);
    
    res.json(rows);
  } catch (err) {
    console.error("Erro ao carregar gêneros:", err);
    res.status(500).json({ error: "Erro ao carregar lista de gêneros" });
  }
};
