import pool from '../db.js';

const CANON = [
  'Romance','Aventura','Fantasia','Ficção Científica','Mistério','Suspense','Terror',
  'Drama','Biografia','História','Religião','Autoajuda','Poesia','Humor','Clássicos',
  'Tecnologia','Negócios','Educação','Infantojuvenil','HQ','Literatura Brasileira',
];

export async function upsertGeneroByName(nomeRaw) {
  if (!nomeRaw) return null;
  const nome = String(nomeRaw).trim();
  if (!nome) return null;

  const { rows } = await pool.query(
    'INSERT INTO generos (nome) VALUES ($1) ON CONFLICT (nome) DO UPDATE SET nome=EXCLUDED.nome RETURNING id_genero, nome',
    [nome]
  );
  return rows[0];
}

export async function ensureLivroGeneros(id_livro, nomes=[]) {
  const uniq = [...new Set(nomes.map(n => String(n).trim()).filter(Boolean))];
  if (!uniq.length) return { principal: null, count: 0 };

  let principal = null;
  for (const g of uniq) {
    const gen = await upsertGeneroByName(g);
    await pool.query(
      'INSERT INTO livro_genero (id_livro, id_genero) VALUES ($1,$2) ON CONFLICT DO NOTHING',
      [id_livro, gen.id_genero]
    );
    if (!principal && CANON.includes(gen.nome)) principal = gen.id_genero;
  }
  if (!principal) {
    const { rows } = await pool.query(
      'SELECT id_genero FROM livro_genero WHERE id_livro=$1 LIMIT 1', [id_livro]
    );
    principal = rows[0]?.id_genero || null;
  }
  if (principal) {
    await pool.query('UPDATE livros SET genero_principal=$1 WHERE id_livro=$2', [principal, id_livro]);
  }
  return { principal, count: uniq.length };
}
