import pool from '../db.js';
import fetch from 'node-fetch';

// Listar livros
export const getLivros = async (req,res) => {
  try {
    const result = await pool.query('SELECT * FROM livros WHERE status=\'APROVADO\'');
    res.json(result.rows);
  } catch(err) {
    console.error(err);
    res.status(500).json({ error:'Erro ao listar livros' });
  }
};

// Cadastrar livro via ISBN (Google Books)
export const addLivroByISBN = async (req,res) => {
  const { isbn } = req.body;
  if(!isbn) return res.status(400).json({ error:'ISBN obrigatório' });

  try {
    // Verifica duplicado
    const existe = await pool.query('SELECT * FROM livros WHERE isbn=$1', [isbn]);
    if(existe.rows.length > 0) return res.status(400).json({ error:'Livro já cadastrado' });

    // Consulta Google Books API
    const response = await fetch(`https://www.googleapis.com/books/v1/volumes?q=isbn:${isbn}`);
    const data = await response.json();

    if(!data.items) return res.status(404).json({ error:'Livro não encontrado na API' });

    const info = data.items[0].volumeInfo;
    const titulo = info.title || '';
    const autor = (info.authors && info.authors.join(', ')) || '';
    const editora = info.publisher || '';
    const ano_publicacao = info.publishedDate ? parseInt(info.publishedDate.split('-')[0]) : null;
    const capa = info.imageLinks?.thumbnail || '';
    const idioma = info.language || '';
    const num_paginas = info.pageCount || null;
    const descricao = info.description || '';

    const result = await pool.query(
      'INSERT INTO livros (titulo, autor, isbn, editora, ano_publicacao, capa, idioma, num_paginas, descricao, status) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,\'APROVADO\') RETURNING *',
      [titulo, autor, isbn, editora, ano_publicacao, capa, idioma, num_paginas, descricao]
    );

    res.json({ success:true, livro: result.rows[0] });

  } catch(err) {
    console.error(err);
    res.status(500).json({ error:'Erro ao cadastrar livro' });
  }
};
