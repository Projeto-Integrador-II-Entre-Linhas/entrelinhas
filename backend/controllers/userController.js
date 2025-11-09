import pool from '../db.js';
import bcrypt from 'bcryptjs';

// ------- ADMIN: usuários -------
export const listarUsuarios = async (_req, res) => {
  const { rows } = await pool.query(
    'SELECT id_usuario, nome, usuario, email, perfil, status, data_criacao FROM usuarios ORDER BY id_usuario'
  );
  res.json(rows);
};

export const alterarStatus = async (req, res) => {
  const { id } = req.params;
  const { status, motivo_inativacao } = req.body;
  await pool.query('UPDATE usuarios SET status=$1, motivo_inativacao=$2 WHERE id_usuario=$3', [status, motivo_inativacao || null, id]);
  res.json({ success: true, message: 'Status atualizado' });
};

export const excluirUsuario = async (req, res) => {
  const { id } = req.params;
  await pool.query('DELETE FROM usuarios WHERE id_usuario=$1', [id]);
  res.json({ success: true, message: 'Usuário removido' });
};

export const setPerfil = async (req, res) => {
  const { id } = req.params;
  const { perfil } = req.body; // 'ADMIN' | 'COMUM'
  if (!['ADMIN','COMUM'].includes(perfil)) return res.status(400).json({ error:'Perfil inválido' });
  await pool.query('UPDATE usuarios SET perfil=$1 WHERE id_usuario=$2', [perfil, id]);
  res.json({ success: true, message: 'Perfil atualizado' });
};

// ------- Eu (dados do próprio usuário) -------
export const me = async (req, res) => {
  const { sub } = req.user;
  const { rows } = await pool.query(
    'SELECT id_usuario, nome, email, usuario, avatar, perfil, status, generos_preferidos FROM usuarios WHERE id_usuario=$1',
    [sub]
  );
  if (!rows.length) return res.status(404).json({ error: 'Usuário não encontrado' });
  res.json(rows[0]);
};

// ------- Atualizar perfil (todos os campos + avatar) -------
export const atualizarPerfil = async (req, res) => {
  const id = req.user.sub;
  const { nome, usuario, email, senha, generos_preferidos } = req.body;
  const avatar = req.file ? `/uploads/avatars/${req.file.filename}` : undefined;

  try {
    let hashed;
    if (senha) hashed = await bcrypt.hash(senha, 10);

    const updates = [];
    const values = [];
    let idx = 1;

    if (nome){ updates.push(`nome=$${idx++}`); values.push(nome); }
    if (usuario){ updates.push(`usuario=$${idx++}`); values.push(usuario); }
    if (email){ updates.push(`email=$${idx++}`); values.push(email); }
    if (hashed){ updates.push(`senha=$${idx++}`); values.push(hashed); }
    if (avatar){ updates.push(`avatar=$${idx++}`); values.push(avatar); }
    if (generos_preferidos){
      const arr = Array.isArray(generos_preferidos) ? generos_preferidos : String(generos_preferidos).split(',').map(s=>s.trim()).filter(Boolean);
      updates.push(`generos_preferidos=$${idx++}`); values.push(arr);
    }

    if (!updates.length) return res.status(400).json({ error:'Nada para atualizar' });

    const sql = `UPDATE usuarios SET ${updates.join(', ')} WHERE id_usuario=$${idx} RETURNING id_usuario, nome, usuario, email, avatar, perfil, status, generos_preferidos`;
    values.push(id);

    const { rows } = await pool.query(sql, values);
    res.json({ success: true, user: rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao atualizar perfil' });
  }
};
