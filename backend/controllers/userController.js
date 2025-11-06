// controllers/userController.js
import pool from '../db.js';
import bcrypt from 'bcryptjs';

// --- RF05: Administrar usuários (ADMIN) --- //
export const listarUsuarios = async (_req, res) => {
  const { rows } = await pool.query('SELECT id_usuario, nome, usuario, email, perfil, status, data_criacao FROM usuarios ORDER BY id_usuario');
  res.json(rows);
};

export const alterarStatus = async (req, res) => {
  const { id } = req.params;
  const { status, motivo_inativacao } = req.body;
  await pool.query(
    'UPDATE usuarios SET status=$1, motivo_inativacao=$2 WHERE id_usuario=$3',
    [status, motivo_inativacao || null, id]
  );
  res.json({ success: true, message: 'Status atualizado' });
};

export const excluirUsuario = async (req, res) => {
  const { id } = req.params;
  await pool.query('DELETE FROM usuarios WHERE id_usuario=$1', [id]);
  res.json({ success: true, message: 'Usuário removido' });
};

// --- RF11: Atualizar perfil do usuário (com avatar) --- //
export const atualizarPerfil = async (req, res) => {
  const id = req.user.sub;
  const { nome, usuario, email, senha } = req.body;
  const avatar = req.file ? `/uploads/${req.file.filename}` : undefined;

  try {
    let hashed = undefined;
    if (senha) hashed = await bcrypt.hash(senha, 10);

    const updates = [];
    const values = [];
    let index = 1;

    if (nome) { updates.push(`nome=$${index++}`); values.push(nome); }
    if (usuario) { updates.push(`usuario=$${index++}`); values.push(usuario); }
    if (email) { updates.push(`email=$${index++}`); values.push(email); }
    if (hashed) { updates.push(`senha=$${index++}`); values.push(hashed); }
    if (avatar) { updates.push(`avatar=$${index++}`); values.push(avatar); }

    const sql = `UPDATE usuarios SET ${updates.join(', ')} WHERE id_usuario=$${index} RETURNING id_usuario, nome, email, usuario, avatar`;
    values.push(id);

    const { rows } = await pool.query(sql, values);
    res.json({ success: true, user: rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erro ao atualizar perfil' });
  }
};
