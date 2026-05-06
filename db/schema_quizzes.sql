-- =================================================================
-- SCHEMA DOS TESTES COM PERGUNTAS E RESPOSTAS
-- =================================================================

-- Criar o schema quizzes
CREATE SCHEMA IF NOT EXISTS quizzes;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Tabela com os tipos de teste. Permite cadastrar, ativar e desativar tipos
CREATE TABLE quizzes.tipos_de_teste (
    id smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo text NOT NULL UNIQUE,
    nome text NOT NULL,
    descricao text,
    ordem smallint DEFAULT 0,
    ativo boolean NOT NULL DEFAULT true,
    criado_em timestamptz NOT NULL DEFAULT now(),
    atualizado_em timestamptz NOT NULL DEFAULT now()
);

-- Tabela que armazena os testes, substituindo quizzes.json
CREATE TABLE quizzes.testes (
    id uuid PRIMARY KEY DEFAULT gen_random_uiid(),
    tipo_id smallint NOT NULL REFERENCES quizzes.tipos_de_teste(id),
    titulo text NOT NULL,
    slug text NOT NULL UNIQUE,
    descricao text,
    duracao smallint NOT NULL,
    imagem text NOT NULL,
    texto_alternativo text NOT NULL,
    ativo boolean NOT NULL DEFAULT true,
    criado_em timestamptz NOT NULL DEFAULT now(),
    atualizado_em timestamptz NOT NULL DEFAULT now()
);

-- Tabela que configura algoritmo de cálculo de cada teste, substituindo regras hardcoded
CREATE TABLE quizzes.regras_de_pontuacao (
    id uuid PRIMARY KEY DEFAULT gen_random_uiid(),
    teste_id uuid NOT NULL UNIQUE REFERENCES quizzes.testes(id),
    agregacao text NOT NULL (
        agregacao IN ('contar_sim', 'soma', 'media', 'percentual')
    ),
    pontuacao_maxima_por_categoria smallint,
    configuracao JSONB,
    criado_em timestamptz NOT NULL DEFAULT now(),
    atualizado_em timestamptz NOT NULL DEFAULT now()
);

-- Agrupamento de perguntas no teste, necessário para testes onde as perguntas se dividem
CREATE TABLE quizzes.grupos_de_perguntas (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    teste_id uuid NOT NULL REFERENCES quizzes.testes(id),
    nome text,
    descricao text,
    ordem smallint NOT NULL,
    ativo boolean NOT NULL DEFAULT true,
    criado_em timestamptz NOT NULL DEFAULT now(),
    atualizado_em timestamptz NOT NULL DEFAULT now()
);

-- Tabela armazena o enunciado das perguntas
CREATE TABLE quizzes.perguntas (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    teste_id uuid NOT NULL REFERENCES quizzes.testes(id),
    grupo_de_perguntas_id uuid REFERENCES quizzes.grupos_de_perguntas(id),
    enunciado text NOT NULL,
    feedback text,
    peso numeric DEFAULT 1.0,
    ordem smallint,
    ativo boolean NOT NULL DEFAULT true
    criado_em timestamptz NOT NULL DEFAULT now(),
    atualizado_em timestamptz NOT NULL DEFAULT now()
);

-- Tabela armazena as alternativas das perguntas de múltiplas escolha e Likert
CREATE TABLE quizzes.alternativas (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    pergunta_id uuid NOT NULL REFERENCES quizzes.perguntas(id),
    texto text NOT NULL,
    categoria text,
    pontuacao numeric,
    ordem smallint NOT NULL,
    ativo boolean NOT NULL DEFAULT true,
    criado_em timestamptz NOT NULL DEFAULT now(),
    atualizado_em timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT alternativa_tem_valor CHECK (categoria IS NOT NULL OR pontuacao IS NOT NULL)
);

-- Tabela com textos descritivos de cada perfil/categoria
CREATE TABLE quizzes.perfis_de_resultado (
    id smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    teste_id uuid NOT NULL REFERENCES quizzes.testes(id),
    categoria text NOT NULL,
    titulo text NOT NULL,
    descricao text NOT NULL,
    pontos_fortes text,
    pontos_fracos text,
    ativo boolean NOT NULL DEFAULT true,
    criado_em timestamptz NOT NULL DEFAULT now(),
    atualizado_em timestamptz NOT NULL DEFAULT now()
);

--Tabela que define quando cada perfil é exibido com base na pontuação
CREATE TABLE quizzes.faixas_de_resultado (
    id smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    perfil_id smallint NOT NULL REFERENCES quizzes.perfis_de_resultado(id),
    pontuacao_minima numeric NOT NULL,
    pontuacao_maxima numeric NOT NULL,
    ativo boolean NOT NULL DEFAULT true,
    criado_em timestamptz NOT NULL DEFAULT now(),
    atualizado_em timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT faixa_valida CHECK (pontuacao_minima <= pontuacao_maxima)
);

-- =================================================================
-- CRIAÇÃO DE TRIGGER PARA AS COLUNAS "atualiza_em" FUNCIONAR
-- =================================================================

-- Função genérica que será reutilizada por todas as triggers
CREATE OR REPLACE FUNCTION quizzes.atualizar_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.atualizado_em = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplcar função em todas as tabelas com coluna "atualizado_em"


-- =================================================================
-- CRIAÇÃO DOS ÍNDICES PARA AS CHAVES ESTRANGEIRAS (FK)
-- =================================================================

CREATE INDEX idx_perguntas_teste_id ON quizzes.perguntas(teste_id);
CREATE INDEX idx_perguntas_grupo_id ON quizzes.perguntas(grupo_de_perguntas_id);
CREATE INDEX idx_alternativas_pergunta_id ON quizzes.alternativas(pergunta_id);
CREATE INDEX idx_grupos_teste_id ON quizzes.grupos_de_perguntas(teste_id);
CREATE INDEX idx_perfis_teste_id ON quizzes.perfis_de_resultado(teste_id);
CREATE INDEX idx_faixas_perfil_id ON quizzes.faixas_de_resultado(perfil_id);