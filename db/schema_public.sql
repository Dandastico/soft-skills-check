-- =================================================================
-- SCHEMA QUE ARMAZENA TESTES REALIZADOS PELOS USUÁRIOS
-- =================================================================

-- Armazena cada início de teste do usuário
CREATE TABLE public.sessoes_de_teste (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    teste_id uuid NOT NULL REFERENCES quizzes.testes(id) ON DELETE RESTRICT,
    criado_em timestamptz NOT NULL DEFAULT now(),
    concluido_em timestamptz,
    CONSTRAINT concluido_apos_criado CHECK (
        concluido_em IS NULL OR concluido_em >= criado_em
    )
);

-- Uma linha por resposta do usuário
CREATE TABLE public.respostas_do_usuario (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sessao_id uuid NOT NULL REFERENCES public.sessoes_de_teste(id) ON DELETE CASCADE,
    pergunta_id uuid NOT NULL REFERENCES quizzes.perguntas(id) ON DELETE RESTRICT,
    resposta_booleana boolean,
    resposta_numerica numeric,
    criado_em timestamptz NOT NULL DEFAULT now(),
    atualizado_em timestamptz,
    UNIQUE (sessao_id, pergunta_id)
);

-- Liga respostas às alternativas escolhidas. Permite perguntas que aceita múltiplas seleções
CREATE TABLE public.respostas_alternativas (
    resposta_id uuid NOT NULL REFERENCES public.respostas_do_usuario(id) ON DELETE CASCADE,
    alternativa_id uuid NOT NULL REFERENCES quizzes.alternativas(id) ON DELETE RESTRICT,
    ordem_da_selecao smallint,
    PRIMARY KEY (resposta_id, alternativa_id)
);

-- Pontuação calculada por categoria ao final de cada sessão.
-- Importante pra não ficar recalculando resultados e entrega resultado pronto pra IA
CREATE TABLE public.resultados_de_teste (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    sessao_id uuid NOT NULL REFERENCES public.sessoes_de_teste(id) ON DELETE CASCADE,
    categoria text NOT NULL,
    pontuacao numeric NOT NULL CHECK (pontuacao >= 0),
    UNIQUE (sessao_id, categoria)
);

-- =================================================================
-- CRIAÇÃO DOS ÍNDICES PARA AS CHAVES ESTRANGEIRAS (FK)
-- =================================================================

-- sessoes_de_teste
CREATE INDEX idx_sessoes_usuario ON public.sessoes_de_teste(usuario_id);
CREATE INDEX idx_sessoes_teste ON public.sessoes_de_teste(teste_id);
-- respostas_do_usuario
CREATE INDEX idx_respostas_pergunta ON public.respostas_do_usuario(pergunta_id);
-- respostas_alternativas
CREATE INDEX idx_resp_alt ON public.respostas_alternativas(alternativa_id);