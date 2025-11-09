// controllers/livroController.js
import pool from '../db.js';
import fetch from 'node-fetch';
import { ensureLivroGeneros } from '../utils/genres.js';

// -------- Fallback compatível: converte capa/capa_url --------
function capaAlias(row) {
  if (!row) return row;
  if (row.capa_url === undefined && row.capa !== undefined) {
    row.capa_url = row.capa;
  }
  return row;
}

// ==========================================================
//  RF09 - FILTROS: autor, título, gênero
// ==========================================================
export const getLivros = async (req, res) => {
  const { autor, titulo, genero } = req.query;
  let sql = `SELECT * FROM livros WHERE status='APROVADO'`;
  const params = [];

  if (autor) {
    params.push(`%${autor}%`);
    sql += ` AND autor ILIKE $${params.length}`;
  }
  if (titulo) {
    params.push(`%${titulo}%`);
    sql += ` AND titulo ILIKE $${params.length}`;
  }
  if (genero) {
    params.push(`%${genero}%`);
    sql += ` AND id_livro IN (
      SELECT lg.id_livro FROM livro_genero lg
      JOIN generos g ON g.id_genero = lg.id_genero
      WHERE g.nome ILIKE $${params.length}
    )`;
  }

  try {
    const { rows } = await pool.query(sql, params);
    res.json(rows.map(capaAlias));
  } catch (err) {
    console.error('getLivros:', err);
    res.status(500).json({ error: 'Erro ao buscar livros' });
  }
};

// ==========================================================
//  RF12 - Detalhes do livro + fichamentos públicos
// ==========================================================
export const getLivroDetalhes = async (req, res) => {
  const { id } = req.params;
  try {
    const livro = await pool.query('SELECT * FROM livros WHERE id_livro=$1', [id]);
    if (!livro.rows.length)
      return res.status(404).json({ error: 'Livro não encontrado' });

    const fichamentos = await pool.query(
      "SELECT * FROM fichamentos WHERE id_livro=$1 AND visibilidade='PUBLICO' ORDER BY data_criacao DESC",
      [id]
    );

    res.json({ livro: capaAlias(livro.rows[0]), fichamentos: fichamentos.rows });
  } catch (err) {
    console.error('getLivroDetalhes:', err);
    res.status(500).json({ error: 'Erro ao buscar detalhes do livro' });
  }
};

// ==========================================================
//  FUNÇÕES AUXILIARES - APIs Externas (Google / OpenLibrary)
// ==========================================================
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

  const generos = (info.categories || []).map(c => String(c).split('/')).flat().map(s => s.trim());

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

// ==========================================================
//  RF06 - Cadastrar Livro por ISBN (Google → OpenLibrary fallback)
// ==========================================================
export const addLivroByISBN = async (req, res) => {
  const { isbn } = req.body;
  if (!isbn) return res.status(400).json({ error: 'ISBN é obrigatório' });

  try {
    const exists = await pool.query('SELECT * FROM livros WHERE isbn=$1', [isbn]);
    if (exists.rows.length > 0) return res.status(200).json(capaAlias(exists.rows[0]));

    let meta = await fetchGoogleByISBN(isbn);
    if (!meta) meta = await fetchOpenLibraryByISBN(isbn);
    if (!meta)
      return res.status(404).json({ error: 'Livro não encontrado em fontes públicas' });

    const result = await pool.query(
      `INSERT INTO livros 
        (titulo, autor, descricao, capa_url, editora, ano_publicacao, isbn, idioma, num_paginas, status, fonte_api)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,'APROVADO',$10)
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
        meta.fonte,
      ]
    );

    const livro = result.rows[0];
    await ensureLivroGeneros(livro.id_livro, meta.generos || []);

    res.status(201).json(capaAlias(livro));
  } catch (err) {
    console.error('Erro ao adicionar livro:', err);
    res.status(500).json({ error: 'Erro ao adicionar livro' });
  }
};

// ==========================================================
//  RF06 - Buscar Livro (Google Books + fallback OpenLibrary por título ou ISBN)
// ==========================================================
export const searchLivrosGoogle = async (req, res) => {
  const { titulo, isbn } = req.query;
  if ((!titulo || !titulo.trim()) && (!isbn || !isbn.trim())) {
    return res.status(400).json({ error: 'Informe título ou ISBN.' });
  }

  try {
    const q = isbn ? `isbn:${isbn.trim()}` : `intitle:${encodeURIComponent(titulo.trim())}`;
    console.log('Buscando no Google Books:', q);

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
          if (!isbnId) return null;
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
        .filter(Boolean);
    }

    if (out.length) {
      console.log(`Google Books retornou ${out.length} resultados`);
      return res.json(out);
    }

    // ======================================================
    // Fallback: tenta OpenLibrary com título ou ISBN
    // ======================================================
    if (isbn) {
      console.log('Buscando no OpenLibrary por ISBN:', isbn);
      const or = await fetch(`https://openlibrary.org/isbn/${encodeURIComponent(isbn)}.json`);
      if (or.ok) {
        const data = await or.json();
        const cover = data.covers?.length
          ? `https://covers.openlibrary.org/b/id/${data.covers[0]}-L.jpg`
          : '';

        const autor = data.authors?.length
          ? (await (await fetch(`https://openlibrary.org${data.authors[0].key}.json`)).json()).name
          : 'Autor desconhecido';

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

        console.log('OpenLibrary retornou resultado por ISBN');
        return res.json([livro]);
      }
    }

    if (titulo) {
      console.log('Buscando no OpenLibrary por título:', titulo);
      const or = await fetch(
        `https://openlibrary.org/search.json?title=${encodeURIComponent(titulo)}&limit=15`
      );
      const odata = or.ok ? await or.json() : {};
      const mapped = (odata.docs || [])
        .map(d => {
          const cover = d.cover_i
            ? `https://covers.openlibrary.org/b/id/${d.cover_i}-M.jpg`
            : '';
          const isbnOL = d.isbn?.length ? d.isbn[0] : null;
          if (!isbnOL) return null;
          return {
            titulo: d.title || 'Título desconhecido',
            autores: d.author_name || [],
            descricao: '',
            capa_url: cover,
            editora: Array.isArray(d.publisher) ? d.publisher[0] : '',
            ano_publicacao: d.first_publish_year || '',
            google_id: null,
            isbn: isbnOL,
          };
        })
        .filter(Boolean);

      if (mapped.length) {
        console.log(`OpenLibrary retornou ${mapped.length} resultados por título`);
        return res.json(mapped);
      }
    }

    console.log('Nenhum resultado em Google Books nem OpenLibrary');
    return res.status(404).json({ error: 'Nenhum livro encontrado.' });
  } catch (err) {
    console.error('searchLivrosGoogle:', err);
    res.status(500).json({ error: 'Erro ao buscar livro.' });
  }
};
