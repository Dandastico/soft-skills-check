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
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
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
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    teste_id uuid NOT NULL UNIQUE REFERENCES quizzes.testes(id),
    agregacao text NOT NULL CHECK (
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
    ativo boolean NOT NULL DEFAULT true,
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
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
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

-- Tabela que define sessões de testes aplicadas de maneira específicas
CREATE TABLE quizzes.aplicacoes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    teste_id uuid NOT NULL REFERENCES quizzes.testes(id),
    aplicador_id uuid REFERENCES auth.users(id), -- a professora, por exemplo
    organizacao_id smallint REFERENCES usuarios.organizacoes(id), -- SENAC, por exemplo
    nome text NOT NULL, -- ex.: "Turma ADS Noturno B - 2026/1"
    codigo_acesso text UNIQUE, -- código que alunos digitam para ingressar no teste
    permite_anonimo boolean NOT NULL DEFAULT false, -- obriga o usuário a se autenticar ou não
    inicia_em timestamptz,
    encerra_em timestamptz,
    ativo boolean NOT NULL DEFAULT true,
    criado_em timestamptz NOT NULL DEFAULT now(),
    atualizado_em timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT janela_valida CHECK (
        inicia_em IS NULL OR encerra_em IS NULL OR inicia_em <= encerra_em
    )
);

--Tabela que define quando cada perfil é exibido com base na pontuação
CREATE TABLE quizzes.faixas_de_resultado (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    perfil_de_resultado_id uuid NOT NULL REFERENCES quizzes.perfis_de_resultado(id),
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

-- Aplicar função em todas as tabelas com coluna "atualizado_em"
CREATE TRIGGER trg_tipos_de_teste_atualizar_timestamp
    BEFORE UPDATE ON quizzes.tipos_de_teste
    FOR EACH ROW
    EXECUTE FUNCTION quizzes.atualizar_timestamp();

CREATE TRIGGER trg_testes_atualizar_timestamp
    BEFORE UPDATE ON quizzes.testes
    FOR EACH ROW
    EXECUTE FUNCTION quizzes.atualizar_timestamp();

CREATE TRIGGER trg_regras_atualizar_timestamp
    BEFORE UPDATE ON quizzes.regras_de_pontuacao
    FOR EACH ROW
    EXECUTE FUNCTION quizzes.atualizar_timestamp();

CREATE TRIGGER trg_grupos_de_perguntas_atualizar_timestamp
    BEFORE UPDATE ON quizzes.grupos_de_perguntas
    FOR EACH ROW
    EXECUTE FUNCTION quizzes.atualizar_timestamp();

CREATE TRIGGER trg_perguntas_atualizar_timestamp
    BEFORE UPDATE ON quizzes.perguntas
    FOR EACH ROW
    EXECUTE FUNCTION quizzes.atualizar_timestamp();

CREATE TRIGGER trg_alternativas_atualizar_timestamp
    BEFORE UPDATE ON quizzes.alternativas
    FOR EACH ROW
    EXECUTE FUNCTION quizzes.atualizar_timestamp();

CREATE TRIGGER trg_perfis_atualizar_timestamp
    BEFORE UPDATE ON quizzes.perfis_de_resultado
    FOR EACH ROW
    EXECUTE FUNCTION quizzes.atualizar_timestamp();

CREATE TRIGGER trg_faixas_atualizar_timestamp
    BEFORE UPDATE ON quizzes.faixas_de_resultado
    FOR EACH ROW
    EXECUTE FUNCTION quizzes.atualizar_timestamp();

CREATE TRIGGER trg_aplicacoes_atualizar_timestamp
    BEFORE UPDATE ON quizzes.aplicacoes
    FOR EACH ROW
    EXECUTE FUNCTION quizzes.atualizar_timestamp();

-- =================================================================
-- CRIAÇÃO DOS ÍNDICES PARA AS CHAVES ESTRANGEIRAS (FK)
-- =================================================================

CREATE INDEX idx_perguntas_teste_id ON quizzes.perguntas(teste_id);
CREATE INDEX idx_perguntas_grupo_id ON quizzes.perguntas(grupo_de_perguntas_id);
CREATE INDEX idx_alternativas_pergunta_id ON quizzes.alternativas(pergunta_id);
CREATE INDEX idx_grupos_teste_id ON quizzes.grupos_de_perguntas(teste_id);
CREATE INDEX idx_perfis_teste_id ON quizzes.perfis_de_resultado(teste_id);
CREATE INDEX idx_faixas_perfil_id ON quizzes.faixas_de_resultado(perfil_de_resultado_id);
CREATE INDEX idx_aplicacoes_teste_id ON quizzes.aplicacoes(teste_id);
CREATE INDEX idx_aplicacoes_aplicador_id ON quizzes.aplicacoes(aplicador_id);
CREATE INDEX idx_aplicacoes_organizacao_id ON quizzes.aplicacoes(organizacao_id);