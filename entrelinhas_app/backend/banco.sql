-- Active: 1761795540932@@127.0.0.1@5432@entrelinhas_app

-- Cria o banco de dados
CREATE DATABASE entrelinhas_app;
\c entrelinhas_app;

-- ==========================================================
-- 1. Criação dos tipos ENUM
-- ==========================================================

CREATE TYPE perfil_usuario AS ENUM ('ADMIN', 'COMUM');
CREATE TYPE status_usuario AS ENUM ('ATIVO', 'INATIVO');
CREATE TYPE status_livro AS ENUM ('PENDENTE', 'APROVADO', 'REJEITADO');
CREATE TYPE visibilidade_fichamento AS ENUM ('PRIVADO', 'PUBLICO');
CREATE TYPE formato_leitura AS ENUM ('e-reader', 'audiobook', 'fisico');

-- ==========================================================
-- 2. Tabela: usuarios
-- ==========================================================

CREATE TABLE usuarios (
    id_usuario SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    usuario VARCHAR(50) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,
    avatar VARCHAR(255),
    perfil perfil_usuario NOT NULL DEFAULT 'COMUM',
    status status_usuario NOT NULL DEFAULT 'ATIVO',
    token_recuperacao VARCHAR(255),
    expira_token TIMESTAMP,
    data_criacao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_ultimo_login TIMESTAMP,
    motivo_inativacao VARCHAR(100)
);

-- ==========================================================
-- 3. Tabela: livros
-- ==========================================================

CREATE TABLE livros (
    id_livro SERIAL PRIMARY KEY,
    titulo VARCHAR(255) NOT NULL,
    autor VARCHAR(255) NOT NULL,
    capa VARCHAR(500),
    isbn VARCHAR(20) NOT NULL UNIQUE,
    ano_publicacao INT NOT NULL,
    editora VARCHAR(255) NOT NULL,
    num_paginas INT,
    descricao TEXT,
    idioma VARCHAR(50),
    edicao INT,
    status status_livro NOT NULL DEFAULT 'PENDENTE'
);

-- ==========================================================
-- 4. Tabela: solicitacoes_livros
-- ==========================================================

CREATE TABLE solicitacoes_livros (
    id_solicitacao SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_livro INT,
    data_solicitacao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_livro) REFERENCES livros (id_livro) ON DELETE SET NULL
);

-- ==========================================================
-- 5. Tabela: fichamentos
-- ==========================================================

CREATE TABLE fichamentos (
    id_fichamento SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_livro INT NOT NULL,
    introducao TEXT NOT NULL,
    espaco TEXT,
    personagens TEXT,
    narrativa TEXT,
    conclusao TEXT,
    visibilidade visibilidade_fichamento NOT NULL DEFAULT 'PRIVADO',
    data_criacao TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    data_atualizacao TIMESTAMP,
    data_inicio DATE NOT NULL,
    data_fim DATE,
    formato formato_leitura NOT NULL,
    frase_favorita TEXT,
    nota INT NOT NULL CHECK (nota >= 0 AND nota <= 10),
    FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_livro) REFERENCES livros (id_livro) ON DELETE CASCADE
);

-- ==========================================================
-- 6. Tabela: favoritos
-- ==========================================================

CREATE TABLE favoritos (
    id_favorito SERIAL PRIMARY KEY,
    id_usuario INT NOT NULL,
    id_fichamento INT NOT NULL,
    FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario) ON DELETE CASCADE,
    FOREIGN KEY (id_fichamento) REFERENCES fichamentos (id_fichamento) ON DELETE CASCADE,
    UNIQUE (id_usuario, id_fichamento) -- evita favoritos duplicados
);

-- ==========================================================
-- 7. Tabela: generos
-- ==========================================================

CREATE TABLE generos (
    id_genero SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE
);

-- ==========================================================
-- 8. Tabela: livro_genero (N:N)
-- ==========================================================

CREATE TABLE livro_genero (
    id_livro INT NOT NULL,
    id_genero INT NOT NULL,
    PRIMARY KEY (id_livro, id_genero),
    FOREIGN KEY (id_livro) REFERENCES livros (id_livro) ON DELETE CASCADE,
    FOREIGN KEY (id_genero) REFERENCES generos (id_genero) ON DELETE CASCADE
);

-- ==========================================================
-- 9. Visualização rápida das tabelas criadas
-- ==========================================================
\dt
