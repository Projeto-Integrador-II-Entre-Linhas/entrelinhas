import pool from '../db.js';
import fetch from 'node-fetch';
import { ensureLivroGeneros } from '../utils/genres.js';

//  Função auxiliar — padroniza campo capa_url
function capaAlias(row) {
  if (!row) return row;
  if (!row.capa_url || row.capa_url.trim() === '') {
    // 🔹 Define imagem padrão se a capa estiver vazia
    row.capa_url = 'https://i.pinimg.com/736x/da/8f/b2/da8fb239479856a78bdd048d038486be.jpg';
  }
  return row;
}

//  RF09 — Listar livros com filtros
export const getLivros = async (req, res) => {
  const { autor, titulo, genero } = req.query;
  let sql = `
    SELECT DISTINCT l.*
      FROM livros l
      LEFT JOIN livro_genero lg ON l.id_livro = lg.id_livro
      LEFT JOIN generos g ON g.id_genero = lg.id_genero
     WHERE l.status = 'APROVADO'
  `;
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
    sql += ` AND g.nome ILIKE $${params.length}`;
  }

  sql += ' ORDER BY l.titulo ASC';

  try {
    const { rows } = await pool.query(sql, params);
    res.json(rows.map(capaAlias));
  } catch (err) {
    console.error('getLivros:', err);
    res.status(500).json({ error: 'Erro ao buscar livros.' });
  }
};

//  RF12 — Detalhes do livro + fichamentos públicos
export const getLivroDetalhes = async (req, res) => {
  const { id } = req.params;
  try {
    const livro = await pool.query('SELECT * FROM livros WHERE id_livro=$1', [id]);
    if (!livro.rows.length)
      return res.status(404).json({ error: 'Livro não encontrado.' });

    const generos = await pool.query(
      `SELECT g.nome FROM generos g
         JOIN livro_genero lg ON lg.id_genero = g.id_genero
        WHERE lg.id_livro = $1`,
      [id]
    );

    const fichamentos = await pool.query(
      `SELECT f.id_fichamento, f.frase_favorita, f.nota, f.visibilidade, f.data_criacao,
              u.nome AS usuario_nome, l.titulo, l.autor, l.capa_url
         FROM fichamentos f
         JOIN usuarios u ON u.id_usuario = f.id_usuario
         JOIN livros l ON l.id_livro = f.id_livro
        WHERE f.id_livro=$1 AND f.visibilidade='PUBLICO'
        ORDER BY f.data_criacao DESC`,
      [id]
    );

    res.json({
      livro: { ...capaAlias(livro.rows[0]), generos: generos.rows.map(g => g.nome) },
      fichamentos: fichamentos.rows,
    });
  } catch (err) {
    console.error('getLivroDetalhes:', err);
    res.status(500).json({ error: 'Erro ao buscar detalhes do livro.' });
  }
};

//  RF06 — Buscar Livro (Google + OpenLibrary por título/ISBN)
export const searchLivrosGoogle = async (req, res) => {
  const { titulo, isbn } = req.query;
  if ((!titulo || !titulo.trim()) && (!isbn || !isbn.trim())) {
    return res.status(400).json({ error: 'Informe título ou ISBN.' });
  }

  try {
    const q = isbn ? `isbn:${isbn.trim()}` : `intitle:${encodeURIComponent(titulo.trim())}`;
    const gr = await fetch(`https://www.googleapis.com/books/v1/volumes?q=${q}`);
    const gdata = gr.ok ? await gr.json() : {};
    let out = [];

    if (gdata?.items?.length) {
      out = gdata.items
        .map(item => {
          const info = item.volumeInfo || {};
          const ids = info.industryIdentifiers || [];
          const isbnId =
            ids.find(i => i.type === 'ISBN_13')?.identifier ||
            ids.find(i => i.type === 'ISBN_10')?.identifier;
          if (!isbnId) return null; // ⚠️ Ignora livros sem ISBN

          return {
            titulo: info.title || 'Título desconhecido',
            autores: info.authors || [],
            descricao: info.description || '',
            capa_url: info.imageLinks?.thumbnail || '',
            editora: info.publisher || '',
            ano_publicacao: info.publishedDate?.slice(0, 4),
            google_id: item.id,
            isbn: isbnId,
          };
        })
        .filter(Boolean); // remove os nulls
    }

    if (out.length) return res.json(out);

    // Busca alternativa OpenLibrary (também só com ISBN válido)
    if (isbn) {
      const or = await fetch(`https://openlibrary.org/isbn/${encodeURIComponent(isbn)}.json`);
      if (or.ok) {
        const data = await or.json();
        if (!data?.isbn_10 && !data?.isbn_13) return res.json([]); // ⚠️ ignora sem ISBN

        const cover = data.covers?.length
          ? `https://covers.openlibrary.org/b/id/${data.covers[0]}-L.jpg`
          : '';

        let autor = 'Autor desconhecido';
        try {
          if (data.authors?.length) {
            const a = await (await fetch(`https://openlibrary.org${data.authors[0].key}.json`)).json();
            autor = a.name || autor;
          }
        } catch {}

        const livro = {
          titulo: data.title || 'Título desconhecido',
          autores: [autor],
          descricao: data.notes || '',
          capa_url: cover,
          editora: Array.isArray(data.publishers) ? data.publishers[0] : '',
          ano_publicacao: data.publish_date
            ? parseInt(String(data.publish_date).slice(-4))
            : '',
          google_id: null,
          isbn: isbn,
        };
        return res.json([livro]);
      }
    }

    return res.status(404).json({ error: 'Nenhum livro encontrado com ISBN válido.' });
  } catch (err) {
    console.error('searchLivrosGoogle:', err);
    res.status(500).json({ error: 'Erro ao buscar livro.' });
  }
};

//  Funções auxiliares — APIs externas (GoogleBooks / OpenLibrary)
async function fetchGoogleByISBN(isbn) {
  const r = await fetch(`https://www.googleapis.com/books/v1/volumes?q=isbn:${encodeURIComponent(isbn)}`);
  if (!r.ok) return null;
  const data = await r.json();
  if (!data?.items?.length) return null;

  const info = data.items[0].volumeInfo;
  const ids = info.industryIdentifiers || [];
  const foundISBN =
    ids.find(i => i.type === 'ISBN_13')?.identifier ||
    ids.find(i => i.type === 'ISBN_10')?.identifier ||
    isbn;

  const generos = (info.categories || [])
    .map(c => String(c).split('/'))
    .flat()
    .map(s => s.trim());

  return {
    fonte: 'GoogleBooks',
    titulo: info.title || 'Título desconhecido',
    autor: info.authors?.join(', ') || 'Autor desconhecido',
    descricao: info.description || '',
    capa_url: info.imageLinks?.thumbnail || '',
    editora: info.publisher || '',
    ano_publicacao: info.publishedDate ? parseInt(info.publishedDate.slice(0, 4)) : null,
    idioma: info.language || null,
    num_paginas: info.pageCount || null,
    isbn: foundISBN,
    generos,
  };
}

async function fetchOpenLibraryByISBN(isbn) {
  const r = await fetch(`https://openlibrary.org/isbn/${encodeURIComponent(isbn)}.json`);
  if (!r.ok) return null;
  const b = await r.json();

  let autor = '';
  try {
    if (b.authors?.length) {
      const ar = await fetch(`https://openlibrary.org${b.authors[0].key}.json`);
      if (ar.ok) {
        const a = await ar.json();
        autor = a.name || '';
      }
    }
  } catch {}

  const capa_url = b.covers?.length
    ? `https://covers.openlibrary.org/b/id/${b.covers[0]}-L.jpg`
    : '';

  const generos = (b.subjects || [])
    .map(s => String(s).split('--'))
    .flat()
    .map(s => s.trim())
    .slice(0, 6);

  return {
    fonte: 'OpenLibrary',
    titulo: b.title || 'Título desconhecido',
    autor: autor || 'Autor desconhecido',
    descricao:
      b.description ? (typeof b.description === 'string' ? b.description : b.description.value) : '',
    capa_url,
    editora: Array.isArray(b.publishers) ? b.publishers[0] : '',
    ano_publicacao: b.publish_date ? parseInt(String(b.publish_date).slice(-4)) : null,
    idioma: Array.isArray(b.languages)
      ? b.languages[0]?.key?.split('/').pop() || null
      : null,
    num_paginas: b.number_of_pages || null,
    isbn,
    generos,
  };
}

//  RF06 — Adicionar livro automaticamente por ISBN
export const addLivroByISBN = async (req, res) => {
  const { isbn } = req.body;
  const usuario = req.user;
  if (!isbn) return res.status(400).json({ error: 'ISBN é obrigatório.' });

  try {
    const exists = await pool.query('SELECT * FROM livros WHERE isbn=$1', [isbn]);
    if (exists.rows.length) {
      return res.status(200).json(capaAlias(exists.rows[0]));
    }

    let meta = await fetchGoogleByISBN(isbn);
    if (!meta) meta = await fetchOpenLibraryByISBN(isbn);
    if (!meta) {
      return res.status(404).json({
        error: 'Livro não encontrado em fontes públicas. Utilize o formulário de solicitação.',
      });
    }

    if (!meta.titulo || !meta.autor) {
      return res.status(400).json({
        error: 'Fonte externa não retornou dados suficientes. Faça solicitação manual.',
      });
    }
    const status = 'APROVADO';

    const result = await pool.query(
      `INSERT INTO livros
        (titulo, autor, descricao, capa_url, editora, ano_publicacao, isbn, idioma, num_paginas, status, fonte_api)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
       RETURNING *`,
      [
        meta.titulo,
        meta.autor,
        meta.descricao,
        meta.capa_url,
        meta.editora,
        meta.ano_publicacao,
        meta.isbn,
        meta.idioma,
        meta.num_paginas,
        status,
        meta.fonte,
      ]
    );

    const livro = result.rows[0];
    await ensureLivroGeneros(livro.id_livro, meta.generos || []);
    res.status(201).json(capaAlias(livro));
  } catch (err) {
    console.error('addLivroByISBN:', err);
    res.status(500).json({ error: 'Erro ao adicionar livro.' });
  }
};

//  ADMIN — Atualizar Livro
export const adminUpdateLivro = async (req, res) => {
  const { id } = req.params;
  const body = req.body;

  const camposPermitidos = [
    'titulo', 'autor', 'descricao', 'capa_url', 'editora',
    'ano_publicacao', 'idioma', 'num_paginas', 'status'
  ];

  try {
    const updates = [];
    const values = [];
    let idx = 1;

    for (const key of camposPermitidos) {
      if (body[key] !== undefined) {
        updates.push(`${key}=$${idx++}`);
        values.push(body[key]);
      }
    }

    if (!updates.length) {
      return res.status(400).json({ error: 'Nenhum campo válido para atualizar.' });
    }

    values.push(id);
    const { rows } = await pool.query(
      `UPDATE livros SET ${updates.join(', ')} WHERE id_livro=$${idx} RETURNING *`,
      values
    );

    if (!rows.length) return res.status(404).json({ error: 'Livro não encontrado.' });
    res.json(capaAlias(rows[0]));
  } catch (err) {
    console.error('adminUpdateLivro:', err);
    res.status(500).json({ error: 'Erro ao atualizar livro.' });
  }
};

//  ADMIN — Excluir livro
export const adminDeleteLivro = async (req, res) => {
  const { id } = req.params;
  try {
    await pool.query('DELETE FROM livros WHERE id_livro=$1', [id]);
    res.json({ success: true, message: 'Livro excluído com sucesso.' });
  } catch (err) {
    console.error('adminDeleteLivro:', err);
    res.status(500).json({ error: 'Erro ao excluir livro.' });
  }
};
