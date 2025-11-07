// controllers/fichamentoController.js
import pool from '../db.js';

// RF07 / RN04: Criar ou editar fichamento (um por livro/usuário)
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
    generos // opcional: lista de nomes de gêneros
  } = req.body;

  const id_usuario = req.user.sub;

  try {
    // RN04: apenas um fichamento por livro/usuário
    const dup = await pool.query(
      'SELECT id_fichamento FROM fichamentos WHERE id_usuario=$1 AND id_livro=$2',
      [id_usuario, id_livro]
    );

    if (!id_fichamento && dup.rows.length > 0) {
      return res.status(400).json({ error: 'Você já possui um fichamento para este livro.' });
    }

    let fichamento;

    if (id_fichamento) {
      const sql = `
        UPDATE fichamentos SET
          introducao=$1, espaco=$2, personagens=$3, narrativa=$4, conclusao=$5,
          visibilidade=$6, data_inicio=$7, data_fim=$8, formato=$9,
          frase_favorita=$10, nota=$11, data_atualizacao=NOW()
        WHERE id_fichamento=$12 AND id_usuario=$13
        RETURNING *`;
      const { rows } = await pool.query(sql, [
        introducao, espaco, personagens, narrativa, conclusao,
        visibilidade, data_inicio, data_fim, formato,
        frase_favorita, nota, id_fichamento, id_usuario
      ]);
      fichamento = rows[0];
    } else {
      const sql = `
        INSERT INTO fichamentos
          (id_usuario, id_livro, introducao, espaco, personagens, narrativa, conclusao,
           visibilidade, data_inicio, data_fim, formato, frase_favorita, nota)
        VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)
        RETURNING *`;
      const { rows } = await pool.query(sql, [
        id_usuario, id_livro, introducao, espaco, personagens, narrativa, conclusao,
        visibilidade, data_inicio, data_fim, formato, frase_favorita, nota
      ]);
      fichamento = rows[0];
    }

    // Opcional: vincular gêneros ao livro (caso venha uma lista de nomes)
    if (Array.isArray(generos) && generos.length > 0) {
      // garante existência dos gêneros
      for (const nome of generos) {
        const g = await pool.query('SELECT id_genero FROM generos WHERE nome ILIKE $1', [nome]);
        let id_genero;
        if (g.rows.length === 0) {
          const ins = await pool.query(
            'INSERT INTO generos (nome) VALUES ($1) RETURNING id_genero',
            [nome]
          );
          id_genero = ins.rows[0].id_genero;
        } else {
          id_genero = g.rows[0].id_genero;
        }
        // vincula N:N
        await pool.query(
          'INSERT INTO livro_genero (id_livro, id_genero) VALUES ($1,$2) ON CONFLICT DO NOTHING',
          [id_livro, id_genero]
        );
      }
    }

    return res.json(fichamento);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao salvar fichamento' });
  }
};

// RF08: listar públicos
export const getFichamentosPublicos = async (_req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT f.*, l.titulo, l.autor, l.capa_url
       FROM fichamentos f
       JOIN livros l ON l.id_livro = f.id_livro
       WHERE visibilidade='PUBLICO'
       ORDER BY f.data_atualizacao DESC NULLS LAST, f.data_criacao DESC`
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao buscar fichamentos públicos' });
  }
};

// RF04: meus fichamentos
export const getFichamentosDoUsuario = async (req, res) => {
  const id_usuario = req.user.sub;
  try {
    const { rows } = await pool.query(
      `SELECT f.*, l.titulo, l.autor, l.capa_url
       FROM fichamentos f
       JOIN livros l ON l.id_livro = f.id_livro
       WHERE f.id_usuario = $1
       ORDER BY f.data_atualizacao DESC NULLS LAST, f.data_criacao DESC`,
      [id_usuario]
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao buscar fichamentos do usuário' });
  }
};

// RF07: obter meu fichamento de um livro (para pré-carregar na edição)
export const getMeuFichamentoPorLivro = async (req, res) => {
  const id_usuario = req.user.sub;
  const { id_livro } = req.params;
  try {
    const { rows } = await pool.query(
      `SELECT * FROM fichamentos WHERE id_usuario=$1 AND id_livro=$2`,
      [id_usuario, id_livro]
    );
    res.json(rows[0] || null);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao buscar fichamento do usuário para este livro' });
  }
};
