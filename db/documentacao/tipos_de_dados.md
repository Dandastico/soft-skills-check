# Mapeamento de Dados do Projeto

Análise dos dados existentes no código, como base para a modelagem do banco de dados no Supabase.

---

## 1. Os Testes (quizzes)

Fonte: `src/app/quizzes.json`

Existem **4 testes reais** e **1 link externo** (um curso). Cada teste possui:

| Campo | Exemplo | Observação |
|---|---|---|
| `id` | 1, 2, 3, 4 | Identificador numérico |
| `title` | "Escala de Criatividade" | Título do teste |
| `slug` | "escala-de-criatividade" | Usado na URL |
| `description` | Texto longo | Instrução exibida antes do teste |
| `type` | 0, 1, 2, 3 | Define a mecânica de pontuação |
| `duration` | 2 | Tempo estimado em minutos |
| `image` / `alt` | "team.svg" | Imagem ilustrativa |

---

## 2. Os Tipos de Teste (`type`)

O campo `type` controla a mecânica de pontuação e a interface exibida:

| Tipo | Mecânica | Teste que usa |
|---|---|---|
| `0` | Link externo (sem perguntas) | Curso de Inteligência Emocional |
| `1` | Sim/Não — conta quantos "Sim" | Escala de Criatividade |
| `2` | Múltipla escolha por categoria | Estilos de Liderança e Motivação no Trabalho |
| `3` | Escala Likert com pesos, agrupada | Inteligência Emocional |

---

## 3. As Perguntas

Cada pergunta tem estrutura diferente dependendo do tipo do teste.

**Tipo 1 — Sim/Não:**
```
pergunta + feedback (texto exibido se o usuário respondeu "Sim")
```

**Tipo 2 — Múltipla escolha:**
```
pergunta + alternativas[]
  alternativa: { id, text, categoryValue }
```
O campo `categoryValue` acumula a contagem por categoria.
- Liderança: `"autocrat"`, `"liberal"`, `"democrat"`
- Motivação: `"RP-17"`, `"HB-16"`, `"RS-17"`, `"E-17"`, `"P-16"` — o número após o hífen parece ser um peso da categoria

**Tipo 3 — Escala Likert:**
```
pergunta + alternativas[]
  alternativa: { id, text, weight }  (weight: 1 a 5)
```

---

## 4. As Avaliações — atualmente hardcoded

As avaliações estão fixas dentro de `src/app/autoavaliacao/[slug]/resultados/client.tsx`, vinculadas diretamente ao `quiz.id`. Precisam ser movidas para o banco.

### Criatividade (id=1)
Exibe apenas a pontuação numérica. Sem texto de avaliação estruturado.

### Liderança (id=2)
Para cada um dos 3 perfis possíveis (`autocrat`, `liberal`, `democrat`), exibe:
- Descrição do perfil
- Pontos fortes
- Pontos fracos

### Inteligência Emocional (id=3)
Exibe pontuação para 5 grupos fixos de habilidades:

| Grupo | Descrição |
|---|---|
| Autoconhecimento | Reconhecer emoções, limites e qualidades pessoais |
| Autocontrole | Gerenciar impulsos, emoções e reações |
| Automotivação | Manter foco, iniciativa e otimismo |
| Empatia | Compreender emoções alheias |
| Habilidades Sociais | Construir relacionamentos positivos |

### Motivação no Trabalho (id=4)
Exibe percentual para 5 fatores:

| Fator | Sigla | Descrição |
|---|---|---|
| Relações Profissionais | RP | Desenvolvimento intelectual, autonomia e independência |
| Harmonia e bem-estar | HB | Equilíbrio entre vida pessoal e profissional |
| Relações Sociais | RS | Colaborar e contribuir com a sociedade |
| Estabilidade | E | Segurança financeira e tranquilidade |
| Prestígio | P | Reconhecimento, status e admiração |

---

## 5. Onde os resultados ficam hoje

Tudo fica no **`localStorage` do navegador** — nenhum dado é salvo no servidor:

| Tipo | Chave no localStorage | Estrutura |
|---|---|---|
| Tipo 1 | `lastPoints` | `[{ qID, lastPoints }]` |
| Tipo 2 (Liderança) | `lastResults` | `{ autocrat, liberal, democrat }` |
| Tipo 2 (Motivação) | `lastResults` | `{ RS, RP, HB, E, P }` |
| Tipo 3 | `lastResults` | `{ group1, group2, group3, group4, group5 }` |

Se o usuário limpar o navegador, perde todos os resultados. Esse é o problema central que o banco de dados resolve.

---

## 6. O que vai para o banco

Com base nesta análise, o banco precisará representar os seguintes grupos de dados:

### Dados de conteúdo (migração do JSON e do código)
1. **Testes** — metadata (título, descrição, tipo, duração, imagem)
2. **Perguntas** — vinculadas ao teste
3. **Alternativas** — vinculadas à pergunta, com `categoryValue` ou `weight`
4. **Avaliações** — textos de perfil/grupo hoje hardcoded (descrição, pontos fortes, pontos fracos)

### Dados de usuário (novos, com autenticação)
5. **Usuários** — gerenciado pelo Supabase Auth
6. **Sessões de teste** — registro de quando e qual teste o usuário realizou
7. **Respostas** — o que o usuário respondeu em cada pergunta
8. **Resultados calculados** — pontuação por teste/sessão, pronta para exibição e para a IA
