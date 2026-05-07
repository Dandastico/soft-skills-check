-- =================================================================
-- SCHEMA QUE ARMAZENA DADOS DOS USUÁRIOS
-- =================================================================

-- Criar schema usuarios
CREATE SCHEMA IF NOT EXISTS usuarios;

-- Tabela de domínio: organizações cadastradas
CREATE TABLE usuarios.organizacoes (
    id smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome text NOT NULL UNIQUE,
    tipo text CHECK (tipo IN ('ensino', 'empresa', 'outro')),
    ativo boolean NOT NULL DEFAULT true,
    criado_em timestamptz NOT NULL DEFAULT now(),
    atualizado_em timestamptz NOT NULL DEFAULT now()
);

-- Tabela de dmonínio: cursos de graduação
CREATE TABLE usuarios.cursos (
    id smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome text NOT NULL UNIQUE,
    ativo boolean NOT NULL DEFAULT true,
    criado_em timestamptz NOT NULL DEFAULT true,
    atualizado_em timestamptz NOT NULL DEFAULT now()
);

-- Tabela de domínio: profissões
CREATE TABLE usuarios.profissoes (
    id smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nome text NOT NULL UNIQUE,
    categoria text, -- agrupa para ajudar as análises
    ativo boolean NOT NULL DEFAULT true,
    criado_em timestamptz NOT NULL DEFAULT now(),
    atualizado_em timestamptz NOT NULL DEFAULT now()
);

-- Perfil do usuário (1:1 com auth.users)
CREATE TABLE usuarios.perfis (
    usuario_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    organizacao_id smallint REFERENCES usuario.organizacoes(id),
    curso_id smallint REFERENCES usuarios.cursos(id),
    profissao smallint REFERENCES usuarios.profissoes(id),
    idade smallint CHECK (idade BETWEEN 13 AND 100),
    organizacao_livre text,
    curso_livre text,
    criado_em timestamptz NOT NULL DEFAULT now(),
    atualizado_em timestamptz NOT NULL DEFAULT now()
);

-- =================================================================
-- CRIAÇÃO DE TRIGGER PARA AS COLUNAS "atualiza_em" FUNCIONAR
-- =================================================================

-- Função genérica utilizada nas triggers em "usuarios"
CREATE OR REPLACE FUNCTION usuarios.atualizar_timestamp()
RETURN TRIGGER AS $$
BEGIN
    NEW.atualizado_em = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_organizacoes_atualizar_timestamp
    BEFORE UPDATE ON usuarios.organizacoes
    FOR EACH ROW
    EXECUTE FUNCTION usuarios.atualizar_timestap();

CREATE TRIGGER trg_cursos_atualizar_timestamp
    BEFORE UPDATE ON usuarios.cursos
    FOR EACH ROW
    EXECUTE FUNCTION usuarios.atualizar_timestap();

CREATE TRIGGER trg_perfis_atualizar_timestamp
    BEFORE UPDATE ON usuarios.perfis
    FOR EACH ROW
    EXECUTE FUNCTION usuarios.atualizar_timestap();

-- =================================================================
-- ÍNDICES PARA AS CHAVES ESTRANGEIRAS (FK)
-- =================================================================

CREATE INDEX idx_perfis_organizacao_id ON usuarios.perfis(organizacao_id);
CREATE INDEX idx_perfis_curso_id ON usuarios.perfis(curso_id);