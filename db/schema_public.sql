-- =================================================================
-- SCHEMA QUE ARMAZENA TESTES REALIZADOS PELOS USUÁRIOS
-- =================================================================

-- Armazena cada início de teste do usuário
CREATE TABLE public.sessoes_de_teste (
    id uuid PRIMARY KEY DEFAULT gen_random_v4(),
    usuario_id uuid NOT NULL REFERENCES auth.users(id),
    teste_id uuid NOT NULL REFERENCES quizzes.testes(id),
    criado_em timestamptz NOT NULL DEFAULT now(),
    concluido_em timestamptz DEFAULT now()
);

-- Uma linha por resposta do usuário
CREATE TABLE public.respostas_de_teste (
    id uuid PRIMARY KEY DEFAULT gen_random_v4(),
    sessao_id uuid NOT NULL REFERENCES public.sessoes_de_teste(id),
    pergunta_id uuid NOT NULL REFERENCES quizzes.perguntas(id),
    respsota_booleana boolean,
    resposta_numerica numeric
);

-- Liga respostas às alternativas escolhidas. Permite perguntas que aceita múltiplas seleções
CREATE TABLE public.respostas_alternativas (
    resposta_id uuid NOT NULL REFERENCES public.respostas_de_teste(id),
    alternativas_id uuid NOT NULL REFERENCES quizzes.alternativas(id),
    ordem_da_selecao smallint,
    PRIMARY KEY (resposta_id, alternativas_id)
);

-- Pontuação calculada por categoria ao final de cada sessão.
-- Importante pra não ficar recalculando resultados e entrega resultado pronto pra IA
CREATE TABLE public.resultados_de_teste (
    id uuid PRIMARY KEY DEFAULT gen_random_v4(),
    sessao_id uuid NOT NULL REFERENCES public.sessoes_de_teste(id),
    categoria text NOT NULL,
    pontuacao numeric NOT NULL
);