import pg from 'pg';
const { Pool } = pg;

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 5432),
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'admin',
  database: process.env.DB_NAME || 'entrelinhas_app',
});

pool.query('SELECT 1').then(() => {
  console.log('Postgres conectado');
}).catch((e) => {
  console.error('Falha Postgres:', e);
});

export default pool;