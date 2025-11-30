import dotenv from 'dotenv';
import pool from '../db.js';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import nodemailer from 'nodemailer';

// --- Carrega variáveis do .env
dotenv.config();

const SECRET = process.env.JWT_SECRET || 'dev-secret';
const APP_URL = process.env.APP_URL || 'http://localhost:53878';

//  Função auxiliar: transporte de e-mail
async function getTransport() {
  if (process.env.EMAIL_USER && process.env.EMAIL_PASS) {
    console.log(`Usando Gmail (${process.env.EMAIL_USER})`);
    return nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS,
      },
    });
  }

  // fallback (modo dev)
  const test = await nodemailer.createTestAccount();
  console.log('Usando Ethereal:', test.user, test.pass);
  return nodemailer.createTransport({
    host: 'smtp.ethereal.email',
    port: 587,
    auth: { user: test.user, pass: test.pass },
  });
}

//  REGISTER - Criação de conta
export const register = async (req, res) => {
  const { nome, usuario, email, senha } = req.body;
  if (!nome || !usuario || !email || !senha) {
    return res.status(400).json({ error: 'Todos os campos são obrigatórios' });
  }

  try {
    const exists = await pool.query(
      'SELECT 1 FROM usuarios WHERE email=$1 OR usuario=$2 LIMIT 1',
      [email, usuario]
    );
    if (exists.rows.length > 0) {
      return res.status(409).json({ error: 'Usuário ou e-mail já cadastrado' });
    }

    const hashedPassword = await bcrypt.hash(senha, 10);
    const sql = `
      INSERT INTO usuarios (nome, usuario, email, senha, perfil, status)
      VALUES ($1,$2,$3,$4,'COMUM','ATIVO')
      RETURNING id_usuario, nome, usuario, email, perfil, status, data_criacao
    `;
    const { rows } = await pool.query(sql, [nome, usuario, email, hashedPassword]);

    return res.status(201).json({ success: true, user: rows[0] });
  } catch (err) {
    console.error('REGISTER ERROR:', err);
    if (err.code === '23505') return res.status(409).json({ error: 'Registro duplicado (email/usuario)' });
    if (err.code === '23502') return res.status(400).json({ error: `Campo obrigatório ausente: ${err.column}` });
    return res.status(500).json({ error: err.message });
  }
};

//  LOGIN
export const login = async (req, res) => {
  const { email, senha } = req.body;
  if (!email || !senha) return res.status(400).json({ error: 'Email e senha obrigatórios' });

  try {
    const { rows } = await pool.query('SELECT * FROM usuarios WHERE email=$1 LIMIT 1', [email]);
    if (rows.length === 0) return res.status(401).json({ error: 'Credenciais inválidas' });

    const user = rows[0];
    const ok = await bcrypt.compare(senha, user.senha);
    if (!ok) return res.status(401).json({ error: 'Credenciais inválidas' });

    const token = jwt.sign({ sub: user.id_usuario, perfil: user.perfil }, SECRET, { expiresIn: '7d' });
    await pool.query('UPDATE usuarios SET data_ultimo_login = NOW() WHERE id_usuario=$1', [user.id_usuario]);

    res.json({
      token,
      user: {
        id_usuario: user.id_usuario,
        nome: user.nome,
        email: user.email,
        usuario: user.usuario,
        perfil: user.perfil,
      },
    });
  } catch (err) {
    console.error('LOGIN ERROR:', err);
    res.status(500).json({ error: 'Erro no login' });
  }
};

//  FORGOT PASSWORD - Envio de link clicável
export const forgotPassword = async (req, res) => {
  const { email } = req.body;
  if (!email) return res.status(400).json({ error: 'Email é obrigatório' });

  try {
    const u = await pool.query('SELECT id_usuario FROM usuarios WHERE email=$1', [email]);
    if (u.rows.length === 0) return res.status(404).json({ error: 'Usuário não encontrado' });

    const token = crypto.randomBytes(20).toString('hex');
    const expire = new Date(Date.now() + 3600 * 1000); // 1h
    await pool.query(
      'UPDATE usuarios SET token_recuperacao=$1, expira_token=$2 WHERE email=$3',
      [token, expire, email]
    );

    const transporter = await getTransport();

    // link web
    const webLink = `${APP_URL}/#/reset-password/${token}`;

    await transporter.sendMail({
      from: process.env.EMAIL_USER || 'no-reply@entrelinhas.dev',
      to: email,
      subject: 'Redefinição de senha - EntreLinhas',
      html: `
        <p>Olá!</p>
        <p>Você solicitou a redefinição de senha no <b>EntreLinhas</b>.</p>

        <p><b>Clique no link abaixo (válido por 1h):</b></p>

        <p style="word-break: break-all;">
          <a href="${webLink}">${webLink}</a>
        </p>

        <p>Se você não solicitou, ignore este e-mail.</p>
      `,
    });

    console.log('E-mail de redefinição enviado para', email);
    console.log('Link web:', webLink);

    res.json({ success: true, message: 'Link de redefinição enviado por e-mail' });
  } catch (err) {
    console.error('FORGOT ERROR:', err);
    res.status(500).json({ error: 'Erro ao gerar link de redefinição' });
  }
};

//  RESET PASSWORD - Nova senha
export const resetPassword = async (req, res) => {
  const { token, novaSenha } = req.body;
  if (!token || !novaSenha)
    return res.status(400).json({ error: 'Token e nova senha são obrigatórios' });

  try {
    const userRes = await pool.query(
      `
      SELECT id_usuario 
      FROM usuarios 
      WHERE token_recuperacao=$1 
        AND expira_token > (NOW() AT TIME ZONE 'America/Sao_Paulo')
      `,
      [token]
    );

    if (userRes.rows.length === 0)
      return res.status(400).json({ error: 'Token inválido ou expirado' });

    const hashed = await bcrypt.hash(novaSenha, 10);
    await pool.query(
      'UPDATE usuarios SET senha=$1, token_recuperacao=NULL, expira_token=NULL WHERE id_usuario=$2',
      [hashed, userRes.rows[0].id_usuario]
    );

    res.json({ success: true, message: 'Senha redefinida com sucesso' });
  } catch (err) {
    console.error('RESET ERROR:', err);
    res.status(500).json({ error: 'Erro ao redefinir senha' });
  }
};

