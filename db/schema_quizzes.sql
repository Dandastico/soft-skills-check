-- =================================================================
-- SCHEMA DOS TESTES COM PERGUNTAS E RESPOSTAS
-- =================================================================

-- Tabela com os tipos de teste. Permite cadastrar, ativar e desativar tipos
CREATE TABLE quizzes.tipos_de_teste (
    id smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo text NOT NULL UNIQUE,
    nome text NOT NULL,
    descicao text,
    ordem smallint DEFAULT 0,
    ativo boolean DEFAULT true
);

-- Tabela que armazena os testes, substituindo quizzes.json
CREATE TABLE quizzes.testes (
    id uuid PRIMARY KEY DEFAULT gen_random_v4(),
    tipo_id smallint NOT NULL REFERENCES quizzes.tipos_de_teste(id),
    titulo text NOT NULL,
    slug text UNIQUE,
    descrica text,
    duracao smallint,
    imagem text,
    texto_alternativo text,
    ativo boolean NOT NULL DEFAULT true
);

-- Tabela que configura algoritmo de cálculo de cada teste, substituindo regras hardcoded
CREATE TABLE quizzes.regras_de_pontuacao (
    id uuid PRIMARY KEY DEFAULT gen_random_v4(),
    teste_id uuid NOT NULL REFERENCES quizzes.testes(id),
    agregacao text NOT NULL,
    pontuacao_maxima_por_categoria smallint,
    configuracao JSONB
);

-- Agrupamento de perguntas no teste, necessário para testes onde as perguntas se dividem
CREATE TABLE quizzes.grupos_de_perguntas (
    id uuid PRIMARY KEY DEFAULT gen_random_v4(),
    teste_id uuid NOT NULL REFERENCES quizzes.testes(id),
    nome text,
    descricao text,
    ordem smallint,
    ativo boolean NOT NULL DEFAULT true
);

-- Tabela armazenna o enunciado das perguntas
CREATE TABLE quizzes.perguntas (
    id uuid PRIMARY KEY DEFAULT gen_random_v4(),
    teste_id uuid NOT NULL REFERENCES quizzes.testes(id),
    grupo_de_perguntas_id uuid REFERENCES quizzes.grupos_de_perguntas(id),
    enunciado text NOT NULL,
    feedback text,
    peso numeric DEFAULT 1.0,
    ordem smallint,
    ativo boolean NOT NULL DEFAULT true
);

-- Tabela armazena as alternativas das perguntas de múltiplas escolha e Likert
CREATE TABLE quizzes.alternativas (
    id uuid PRIMARY KEY DEFAULT gen_random_v4(),
    pergunta_id uuid NOT NULL REFERENCES quizzes.perguntas(id),
    texto text NOT NULL,
    caregoria text,
    pontuacao numeric,
    ordem smallint,
    ativo boolean DEFAULT true
);

-- Tabela com textos descritivos de cada perfil/categoria
CREATE TABLE quizzes.perfis_de_resultado (
    id smallint GENERATED ALWAYS AS INDENTITY PRIMARY KEY,
    teste_id uuid NOT NULL REFERENCES quizzes.testes(id),
    categoria text NOT NULL,
    titulo text NOT NULL,
    descricao text NOT NULL,
    pontos_fortes text,
    pontos_fracos text,
    ativo boolean NOT NULL DEFAULT true
);

--Tabela que define quando cada perfil é exibido com base na pontuação
CREATE TABLE quizzes.faixas_de_resultado (
    id smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    perfil_id uuid NOT NULL REFERENCES quizzes.perfis_de_resultado(id),
    pontuacao_minima numeric NOT NULL,
    pontuacao_maxima numeric NOT NULL,
    ativo boolean NOT NULL DEFAULT true
);

