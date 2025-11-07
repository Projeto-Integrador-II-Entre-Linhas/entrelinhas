// controllers/livroController.js
import pool from '../db.js';
import fetch from 'node-fetch';

// RF09: Filtrar livros
export const getLivros = async (req, res) => {
  const { autor, titulo, genero } = req.query;
  let sql = `SELECT * FROM livros WHERE status='APROVADO'`;
  const params = [];

  if (autor) {
    sql += ` AND autor ILIKE $${params.length + 1}`;
    params.push(`%${autor}%`);
  }
  if (titulo) {
    sql += ` AND titulo ILIKE $${params.length + 1}`;
    params.push(`%${titulo}%`);
  }
  if (genero) {
    sql += ` AND id_livro IN (
      SELECT id_livro FROM livro_genero lg
      JOIN generos g ON g.id_genero = lg.id_genero
      WHERE g.nome ILIKE $${params.length + 1}
    )`;
    params.push(`%${genero}%`);
  }

  try {
    const { rows } = await pool.query(sql, params);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao buscar livros' });
  }
};

// RF12: Detalhes + fichamentos públicos
export const getLivroDetalhes = async (req, res) => {
  const { id } = req.params;
  try {
    const livro = await pool.query('SELECT * FROM livros WHERE id_livro=$1', [id]);
    const fichamentos = await pool.query(
      "SELECT * FROM fichamentos WHERE id_livro=$1 AND visibilidade='PUBLICO'",
      [id]
    );
    res.json({ livro: livro.rows[0], fichamentos: fichamentos.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao buscar detalhes do livro' });
  }
};

// RF06: Cadastrar por ISBN (com Google Books)
export const addLivroByISBN = async (req, res) => {
  const { isbn } = req.body;

  try {
    const exists = await pool.query('SELECT 1 FROM livros WHERE isbn=$1', [isbn]);
    if (exists.rows.length > 0) {
      return res.status(200).json({ message: 'Livro já existe', isbn });
    }

    const response = await fetch(
      `https://www.googleapis.com/books/v1/volumes?q=isbn:${encodeURIComponent(isbn)}`
    );
    const data = await response.json();

    if (!data.items || data.totalItems === 0) {
      return res.status(404).json({ error: 'Livro não encontrado na API do Google Books' });
    }

    const info = data.items[0].volumeInfo;

    const titulo = info.title || 'Título desconhecido';
    const autor = info.authors ? info.authors.join(', ') : 'Autor desconhecido';
    const descricao = info.description || '';
    const capa = info.imageLinks?.thumbnail || '';
    const editora = info.publisher || '';
    const ano = info.publishedDate ? parseInt(info.publishedDate.slice(0, 4)) : null;
    const idioma = info.language || null;
    const num_paginas = info.pageCount || null;

    const result = await pool.query(
      `INSERT INTO livros (titulo, autor, descricao, capa_url, editora, ano_publicacao, isbn, idioma, num_paginas, status)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,'APROVADO')
       RETURNING *`,
      [titulo, autor, descricao, capa, editora, ano, isbn, idioma, num_paginas]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Erro ao adicionar livro:', err);
    res.status(500).json({ error: 'Erro ao adicionar livro' });
  }
};

// RF06: Buscar por título ou ISBN na Google Books
export const searchLivrosGoogle = async (req, res) => {
  const { titulo, isbn } = req.query;

  if ((!titulo || titulo.trim() === '') && (!isbn || isbn.trim() === '')) {
    return res.status(400).json({ error: 'Informe um título ou um ISBN para buscar.' });
  }

  try {
    const query = isbn ? `isbn:${isbn}` : `intitle:${encodeURIComponent(titulo)}`;
    const response = await fetch(`https://www.googleapis.com/books/v1/volumes?q=${query}`);
    const data = await response.json();

    if (!data.items || data.totalItems === 0) {
      return res.status(404).json({ error: 'Nenhum livro encontrado.' });
    }

    const livros = data.items
      .map((item) => {
        const info = item.volumeInfo;
        const ids = info.industryIdentifiers || [];
        const isbnItem =
          ids.find((id) => id.type === 'ISBN_13') || ids.find((id) => id.type === 'ISBN_10');

        if (!isbnItem || !info.authors || !info.publishedDate) return null;

        return {
          titulo: info.title || 'Título desconhecido',
          autores: info.authors,
          descricao: info.description || '',
          capaUrl: info.imageLinks?.thumbnail || '',
          editora: info.publisher || '',
          ano_publicacao: info.publishedDate?.slice(0, 4),
          google_id: item.id,
          isbn: isbnItem.identifier
        };
      })
      .filter((l) => l !== null);

    if (livros.length === 0) {
      return res
        .status(404)
        .json({ error: 'Nenhum livro completo encontrado (com ISBN, autor e ano).' });
    }

    res.json(livros);
  } catch (err) {
    console.error('Erro ao buscar livro na API do Google Books:', err);
    res.status(500).json({ error: 'Erro ao buscar livro.' });
  }
};
