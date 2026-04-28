# Modelo de Banco de Dados — Supabase

Proposta de schemas para migração do conteúdo hardcoded e persistência dos dados de usuário.

---

## Visão geral

As tabelas estão divididas em dois grupos:

- **Conteúdo** — migração dos dados hoje no `quizzes.json` e nos componentes React
- **Usuário** — novas tabelas para autenticação e histórico de respostas

```
quizzes
  ├── question_groups
  ├── questions
  │     └── alternatives
  └── result_profiles

auth.users  (gerenciado pelo Supabase Auth)
  └── quiz_sessions
        ├── user_answers  (→ questions, alternatives)
        └── quiz_results
```

---

## Tabelas de conteúdo

### `quizzes`

Metadata de cada teste. Substitui o arquivo `src/app/quizzes.json`.

| Coluna | Tipo | Observação |
|---|---|---|
| `id` | uuid PK | |
| `title` | text | |
| `slug` | text UNIQUE | usado na URL |
| `description` | text | instrução exibida antes do teste |
| `type` | smallint | 0=link externo, 1=sim/não, 2=múltipla escolha, 3=likert |
| `duration` | smallint | tempo estimado em minutos |
| `image` | text | nome do arquivo SVG |
| `alt` | text | descrição acessível da imagem |
| `url` | text | preenchido apenas para type=0 |

---

### `question_groups`

Grupos de perguntas dentro de um teste. Necessário para o quiz de **Inteligência Emocional** (type=3), onde 20 perguntas são divididas em 5 habilidades. Tornar esse agrupamento explícito no banco elimina a dependência implícita de ordenação numérica.

| Coluna | Tipo | Observação |
|---|---|---|
| `id` | uuid PK | |
| `quiz_id` | uuid FK → quizzes | |
| `name` | text | ex: "Autoconhecimento", "Autocontrole" |
| `description` | text | ex: "Capacidade de reconhecer emoções..." |
| `sort_order` | smallint | ordem de exibição |

---

### `questions`

Perguntas de cada teste.

| Coluna | Tipo | Observação |
|---|---|---|
| `id` | uuid PK | |
| `quiz_id` | uuid FK → quizzes | |
| `group_id` | uuid FK → question_groups, nullable | preenchido apenas para type=3 |
| `text` | text | enunciado da pergunta |
| `feedback` | text | texto exibido ao responder "Sim" (type=1) |
| `sort_order` | smallint | |

---

### `alternatives`

Alternativas das perguntas para type=2 e type=3.

O campo `categoryValue` atual (ex: `"RP-17"`) é desmembrado em dois campos separados — `category` e `score` — para permitir consultas e cálculos sem parsing de string.

| Coluna | Tipo | Observação |
|---|---|---|
| `id` | uuid PK | |
| `question_id` | uuid FK → questions | |
| `text` | text | texto da alternativa |
| `category` | text, nullable | ex: `"autocrat"`, `"liberal"`, `"RP"`, `"HB"` |
| `score` | smallint, nullable | peso 1–5 para type=3, ou pontuação 16/17 para Motivação |
| `sort_order` | smallint | |

---

### `result_profiles`

Textos de avaliação hoje hardcoded em `src/app/autoavaliacao/[slug]/resultados/client.tsx`. Cada linha descreve um perfil ou categoria de resultado possível para um determinado teste.

| Coluna | Tipo | Observação |
|---|---|---|
| `id` | uuid PK | |
| `quiz_id` | uuid FK → quizzes | |
| `category` | text | ex: `"autocrat"`, `"RP"`, `"Autoconhecimento"` |
| `title` | text | ex: "Liderança Autocrática" |
| `description` | text | texto descritivo do perfil |
| `strengths` | text, nullable | pontos fortes (usado em Liderança) |
| `weaknesses` | text, nullable | pontos fracos (usado em Liderança) |

---

## Tabelas de usuário

O **Supabase Auth** gerencia os usuários na tabela interna `auth.users`. Não é necessário criar uma tabela `users` própria — as tabelas abaixo referenciam `auth.users` diretamente.

---

### `quiz_sessions`

Registra cada vez que um usuário realiza um teste.

| Coluna | Tipo | Observação |
|---|---|---|
| `id` | uuid PK | |
| `user_id` | uuid FK → auth.users | |
| `quiz_id` | uuid FK → quizzes | |
| `completed_at` | timestamptz, nullable | null se o usuário não concluiu |
| `created_at` | timestamptz | |

---

### `user_answers`

O que o usuário respondeu em cada pergunta de uma sessão.

| Coluna | Tipo | Observação |
|---|---|---|
| `id` | uuid PK | |
| `session_id` | uuid FK → quiz_sessions | |
| `question_id` | uuid FK → questions | |
| `alternative_id` | uuid FK → alternatives, nullable | para type=2 e type=3 |
| `boolean_answer` | boolean, nullable | para type=1 (Sim/Não) |

---

### `quiz_results`

Pontuação calculada por categoria ao final de cada sessão. Armazenar pré-calculado evita recalcular a cada consulta e entrega os dados prontos para a IA gerar avaliações personalizadas.

| Coluna | Tipo | Observação |
|---|---|---|
| `id` | uuid PK | |
| `session_id` | uuid FK → quiz_sessions | |
| `category` | text | ex: `"total"`, `"autocrat"`, `"RP"`, `"group1"` |
| `score` | numeric | valor calculado |

---

## Observações de implementação

- **Row Level Security (RLS):** Ativar no Supabase para garantir que cada usuário acesse apenas seus próprios dados (`quiz_sessions`, `user_answers`, `quiz_results`).
- **Tabelas de conteúdo:** Podem ter acesso público de leitura (sem autenticação), pois não contêm dados pessoais.
- **Cálculo de resultados:** Pode ser feito no cliente (como hoje) ou via função no banco. Para integração com IA, é preferível calcular no servidor e persistir em `quiz_results` antes de chamar o modelo.
