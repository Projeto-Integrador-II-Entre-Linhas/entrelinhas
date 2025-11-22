DROP DATABASE IF EXISTS entrelinhas_app;

CREATE DATABASE entrelinhas_app
    WITH OWNER = postgres
    ENCODING = 'UTF8'
    TEMPLATE template0;


-- =============================================================
-- ENTRELINHAS – BANCO DE DADOS
-- =============================================================

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;

-- ============================================================
-- ENUMS
-- ============================================================

CREATE TYPE formato_leitura AS ENUM ('e-reader','audiobook','fisico');
CREATE TYPE perfil_usuario AS ENUM ('ADMIN','COMUM');
CREATE TYPE status_livro AS ENUM ('PENDENTE','APROVADO','REJEITADO');
CREATE TYPE status_usuario AS ENUM ('ATIVO','INATIVO');
CREATE TYPE visibilidade_fichamento AS ENUM ('PRIVADO','PUBLICO');

-- ============================================================
-- TABELAS BASE
-- ============================================================

CREATE TABLE usuarios (
    id_usuario SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    usuario VARCHAR(50) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,
    avatar VARCHAR(255),
    perfil perfil_usuario DEFAULT 'COMUM' NOT NULL,
    status status_usuario DEFAULT 'ATIVO' NOT NULL,
    token_recuperacao VARCHAR(255),
    expira_token TIMESTAMP,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    data_ultimo_login TIMESTAMP,
    motivo_inativacao VARCHAR(100),
    generos_preferidos TEXT[]
);

CREATE TABLE generos (
    id_genero SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE
);

CREATE INDEX idx_generos_nome ON generos (LOWER(nome));

-- ============================================================
-- LIVROS
-- ============================================================

CREATE TABLE livros (
    id_livro SERIAL PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    autor VARCHAR(255) NOT NULL,
    capa_url VARCHAR(500),
    isbn VARCHAR(20) NOT NULL UNIQUE,
    ano_publicacao INTEGER,
    editora VARCHAR(255) NOT NULL,
    num_paginas INTEGER,
    descricao TEXT,
    idioma VARCHAR(50),
    edicao INTEGER,
    status status_livro DEFAULT 'PENDENTE' NOT NULL,
    motivo_rejeicao TEXT,
    genero_principal INTEGER REFERENCES generos(id_genero),
    fonte_api VARCHAR(100)
);

-- ============================================================
-- VÍNCULO LIVRO → GÊNERO
-- ============================================================

CREATE TABLE livro_genero (
    id_livro INTEGER NOT NULL REFERENCES livros(id_livro) ON DELETE CASCADE,
    id_genero INTEGER NOT NULL REFERENCES generos(id_genero) ON DELETE CASCADE,
    PRIMARY KEY (id_livro, id_genero)
);

CREATE INDEX idx_livro_genero_genero ON livro_genero(id_genero);

-- ============================================================
-- FICHAMENTOS
-- ============================================================

CREATE TABLE fichamentos (
    id_fichamento SERIAL PRIMARY KEY,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    id_livro INTEGER NOT NULL REFERENCES livros(id_livro) ON DELETE CASCADE,

    introducao TEXT NOT NULL,
    espaco TEXT,
    personagens TEXT,
    narrativa TEXT,
    conclusao TEXT,

    visibilidade visibilidade_fichamento DEFAULT 'PRIVADO' NOT NULL,

    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    data_atualizacao TIMESTAMP,

    data_inicio DATE NOT NULL,
    data_fim DATE,

    formato formato_leitura NOT NULL,

    frase_favorita TEXT,
    nota INTEGER NOT NULL CHECK (nota BETWEEN 0 AND 10),

    CONSTRAINT uniq_fichamento_user_book UNIQUE (id_usuario, id_livro)
);

-- ============================================================
-- FICHAMENTO → GÊNEROS
-- ============================================================

CREATE TABLE fichamento_genero (
    id_fichamento INTEGER NOT NULL REFERENCES fichamentos(id_fichamento) ON DELETE CASCADE,
    id_genero INTEGER NOT NULL REFERENCES generos(id_genero),
    PRIMARY KEY (id_fichamento, id_genero)
);

-- ============================================================
-- FAVORITOS
-- ============================================================

CREATE TABLE favoritos (
    id_favorito SERIAL PRIMARY KEY,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    id_fichamento INTEGER NOT NULL REFERENCES fichamentos(id_fichamento) ON DELETE CASCADE,
    UNIQUE (id_usuario, id_fichamento)
);

-- ============================================================
-- SOLICITAÇÕES DE LIVRO
-- ============================================================

CREATE TABLE solicitacoes_livros (
    id_solicitacao SERIAL PRIMARY KEY,
    id_usuario INTEGER NOT NULL REFERENCES usuarios(id_usuario) ON DELETE CASCADE,
    id_livro INTEGER REFERENCES livros(id_livro) ON DELETE SET NULL,

    data_solicitacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,

    titulo VARCHAR(255),
    autor VARCHAR(255),
    ano_publicacao INTEGER,
    editora VARCHAR(255),
    isbn VARCHAR(20),
    descricao TEXT,
    idioma VARCHAR(50),
    num_paginas INTEGER,

    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    status status_livro DEFAULT 'PENDENTE',
    motivo_rejeicao TEXT,
    data_resposta TIMESTAMP
);

-- ============================================================
-- VIEW – FICHAMENTO + GÊNEROS
-- ============================================================

CREATE VIEW vw_fichamento_generos AS
SELECT
    f.id_fichamento,
    ARRAY_AGG(g.nome ORDER BY g.nome) AS generos
FROM fichamentos f
JOIN livro_genero lg ON lg.id_livro = f.id_livro
JOIN generos g ON g.id_genero = lg.id_genero
GROUP BY f.id_fichamento;

-- ============================================================
-- CRIAR USUÁRIOS (Senhas: root, admin) 
-- ============================================================
INSERT INTO usuarios (
    nome,
    email,
    usuario,
    senha,
    perfil,
    status,
    data_criacao,
    generos_preferidos
) VALUES 
(
    'Sr. Root',
    'root@gmail.com',
    'root',
    '$2a$10$wESpIaDPSRQuqpy.pQMGw.GnLmFUKbgUhU0LeaA0XRIKxDaSYMCtG',
    'COMUM',
    'ATIVO',
    CURRENT_TIMESTAMP,
    '{}'::text[]
),
(
    'Sr. Admin',
    'admin@gmail.com',
    'admin',
    '$2a$10$vmxrjYgQsvYCQdBSyc8I6O97F9uvrVHhgq6Ngj3cHrQoOdyWDBbTm',
    'ADMIN',
    'ATIVO',
    CURRENT_TIMESTAMP,
    '{}'::text[]
);
