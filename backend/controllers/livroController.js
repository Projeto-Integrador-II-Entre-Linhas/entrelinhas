// controllers/livroController.js
import pool from '../db.js';
import fetch from 'node-fetch';

// --- RF09: Filtrar livros por autor, título, gênero ---
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

// --- RF12: Livro + fichamentos associados ---
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

// --- RF: Adicionar livro pelo ISBN (Google Books API) ---
export const addLivroByISBN = async (req, res) => {
  const { isbn } = req.body;

  try {
    console.log(`Buscando ISBN ${isbn} na API do Google Books...`);
    const response = await fetch(`https://www.googleapis.com/books/v1/volumes?q=isbn:${isbn}`);
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
    const ano = info.publishedDate ? info.publishedDate.slice(0, 4) : null;

    const result = await pool.query(
      `INSERT INTO livros (titulo, autor, descricao, capa_url, editora, ano_publicacao, isbn, status)
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'APROVADO')
       RETURNING *`,
      [titulo, autor, descricao, capa, editora, ano, isbn]
    );

    console.log('Livro salvo:', result.rows[0]);
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Erro ao adicionar livro:', err);
    res.status(500).json({ error: 'Erro ao adicionar livro' });
  }
};

// --- RFxx: Buscar livro por título OU ISBN na API do Google Books ---
export const searchLivrosGoogle = async (req, res) => {
  const { titulo, isbn } = req.query;

  if ((!titulo || titulo.trim() === '') && (!isbn || isbn.trim() === '')) {
    return res.status(400).json({ error: 'Informe um título ou um ISBN para buscar.' });
  }

  try {
    let query = isbn ? `isbn:${isbn}` : `intitle:${encodeURIComponent(titulo)}`;
    console.log(`Buscando livros com query: ${query}`);

    const response = await fetch(`https://www.googleapis.com/books/v1/volumes?q=${query}`);
    const data = await response.json();

    if (!data.items || data.totalItems === 0) {
      return res.status(404).json({ error: 'Nenhum livro encontrado.' });
    }

    //Filtra apenas livros que tenham ISBN, autor E ano_publicacao
    const livros = data.items
      .map(item => {
        const info = item.volumeInfo;
        const ids = info.industryIdentifiers || [];
        const isbnItem = ids.find(id => id.type === 'ISBN_13') || ids.find(id => id.type === 'ISBN_10');

        if (!isbnItem || !info.authors || !info.publishedDate) return null; // ignora incompletos

        return {
          titulo: info.title || 'Título desconhecido',
          autor: info.authors.join(', '),
          descricao: info.description || '',
          capa_url: info.imageLinks?.thumbnail || '',
          editora: info.publisher || '',
          ano_publicacao: info.publishedDate?.slice(0, 4),
          google_id: item.id,
          isbn: isbnItem.identifier
        };
      })
      .filter(l => l !== null);

    if (livros.length === 0) {
      return res.status(404).json({ error: 'Nenhum livro completo encontrado (com ISBN, autor e ano).' });
    }

    res.json(livros);
  } catch (err) {
    console.error('Erro ao buscar livro na API do Google Books:', err);
    res.status(500).json({ error: 'Erro ao buscar livro.' });
  }
};
