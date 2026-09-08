# core-api-dart

Backend Dart do **bem_comum** (ERP Financeiro): monolito modular em pub workspaces,
um package por bounded context, arquitetura hexagonal, fatia vertical primeiro.

> **Estado.** O código de aplicação ainda **não existe**. O que está montado é o
> harness: regras, hooks de registro, portão de verificação e memória de agentes.

## Como começar

<!-- gerado:toolchain — NÃO EDITE À MÃO; saída de `just readme` -->

| Peça | O quê | Onde está declarado |
|---|---|---|
| Dart SDK | `^3.13.0` | `pubspec.yaml` → `environment.sdk` |
| `just` | task runner | `Justfile` — ponto único de entrada |
| `harness` | hooks e validadores, um executável | `tool/harness/` → `build/harness` |
| CI | GitHub Actions | `.github/workflows/ci.yml` |
| Banco | PostgreSQL 18 — outbox, `SKIP LOCKED`, `LISTEN/NOTIFY` e `pg_cron` no próprio banco | `docs/fontes.yaml` |

> **Legenda.** *Declarado* é o que o repositório exige, não o que está instalado na sua máquina — a versão local varia por máquina e não vale como contrato.

```sh
just --list   # descobre as tarefas
just check    # o portão: rode antes de considerar trabalho pronto
```

<!-- /gerado:toolchain -->

## Tarefas

<!-- gerado:tarefas — NÃO EDITE À MÃO; saída de `just readme` -->

| Tarefa | O que faz | Chama antes |
|---|---|---|
| `just analyze` | Análise estática | `deps` |
| `just build-harness` | Compila o executável do harness em build/harness quando o fonte é mais novo | `deps` |
| `just check` | Portão de verificação — precisa passar antes de considerar qualquer trabalho pronto | `fmt-check`, `analyze`, `test`, `fontes`, `comentarios`, `readme-check` |
| `just comentarios` | Valida a regra de comentários em Dart e em configuração | `build-harness` |
| `just deps` | Resolve as dependências do workspace se ainda não estiverem | — |
| `just diario` | Publica na wiki a página do diário com os commits e prompts do período | `build-harness` |
| `just diario-seco` | Mostra a página do diário sem publicar | `build-harness` |
| `just fmt` | Formata o código | — |
| `just fmt-check` | Formatação — falha se algum arquivo estiver fora do padrão | `deps` |
| `just fontes` | Valida as duas fontes por lib e o _FONTES.md por área de documentação | `build-harness` |
| `just hooks-git` | Instala os hooks de git de .githooks/ (pre-push publica o diário) | — |
| `just log-backup` | Salva o .ai-log fora do repositório, mantendo as 10 cópias mais recentes | `build-harness` |
| `just readme` | Regenera os blocos automáticos do README a partir das fontes de verdade | `build-harness` |
| `just readme-check` | Reprova se o README divergir das fontes de verdade | `build-harness` |
| `just refs-claude` | FALLBACK: baixa a doc do Claude Code/API para disco (gitignorada — posição 6) | `build-harness` |
| `just skills` | Instala/atualiza as skills publicadas pelas dependências, em .agents/skills/ | — |
| `just skills-list` | Lista as skills de package instaladas neste projeto | — |
| `just skills-prune` | Remove skills de dependências que saíram do pubspec | — |
| `just test` | Testes de todo membro do workspace que tenha suíte | `build-harness` |

> **Legenda.** *Chama antes* são as receitas executadas como pré-requisito. `just check` é o portão: o hook `Stop` e o CI rodam exatamente esta receita, para que exista uma só definição de verde.

<!-- /gerado:tarefas -->

## Bounded contexts

<!-- gerado:packages — NÃO EDITE À MÃO; saída de `just readme` -->

_Nenhum package ainda._ O código de aplicação não existe; o que está montado é o harness. Cada bounded context nasce como um package sob `packages/`, e aparece aqui sozinho a partir do seu `pubspec.yaml`.

<!-- /gerado:packages -->

## Onde estão as decisões

<!-- gerado:regras — NÃO EDITE À MÃO; saída de `just readme` -->

| Regra | Assunto |
|---|---|
| [`verificacao.md`](.claude/rules/verificacao.md) | Os três rótulos, e o que conta como prova |
| [`regressao-zero.md`](.claude/rules/regressao-zero.md) | Vermelho é regressão · não reverter trabalho alheio |
| [`dart-style.md`](.claude/rules/dart-style.md) | **Dart de sabor Swift** — imutabilidade, `sealed`, `Result`, isolates |
| [`documentacao.md`](.claude/rules/documentacao.md) | Cascata de fontes · duas fontes por lib · `_FONTES.md` por pasta |
| [`comentarios.md`](.claude/rules/comentarios.md) | **Só dartdoc sobre estrutura** · config diz o quê, nunca o porquê |
| [`idioma.md`](.claude/rules/idioma.md) | Código em EN, texto para pessoas em PT-BR |
| [`segredos.md`](.claude/rules/segredos.md) | Convenção `[SECRET:NOME]` e `[NOLOG]` |
| [`diario-de-bordo.md`](.claude/rules/diario-de-bordo.md) | Diário na wiki, publicado a cada push |

> **Legenda.** Estas regras valem para pessoas e para agentes de IA igualmente. O `CLAUDE.md` na raiz carrega inteiro em toda sessão e aponta para elas.

<!-- /gerado:regras -->

## Documentação

<!-- gerado:docs — NÃO EDITE À MÃO; saída de `just readme` -->

| Lib / ferramenta | Usada para | Fontes, na ordem de consulta |
|---|---|---|
| `claude-code` | Harness de IA deste repositório — hooks, regras, permissões, portão | `llms-txt` → `cli` → `offline` |
| `claude-api` | Referência da API Anthropic quando o projeto integrar LLM | `llms-txt` → `raw-source` → `offline` |
| `dart-sdk` | Linguagem e toolchain do backend (3.13.2 stable, bundled do Flutter) | `mcp` → `cli` → `web-fetch` |
| `lints` | Lints oficiais do time do Dart — base do `analysis_options.yaml` (6.1.0) | `mcp` → `cli` → `raw-source` |
| `test` | Framework de testes do Dart — suíte do portão (`just test`) | `mcp` → `cli` → `raw-source` |
| `mockito` | Mocks gerados para dependências externas nos testes (5.8.1) | `mcp` → `cli` → `raw-source` |
| `build_runner` | Gerador que produz os mocks do `mockito` (2.16.1) | `mcp` → `cli` |
| `yaml` | Leitura de YAML no harness — catálogo, pubspec e workflows (3.1.x) | `mcp` → `raw-source` |
| `args` | Parsing de argumentos no executável do harness (2.7.x) | `mcp` → `raw-source` |
| `postgresql` | PostgreSQL 18 — outbox, `SKIP LOCKED`, `LISTEN/NOTIFY` e `pg_cron` no próprio banco | `mcp` → `web-fetch` |
| `just` | Task runner — ponto único de entrada (`just check` é o portão) | `cli` → `web-fetch` |

> **Legenda.** A ordem é a cascata: **MCP → `llms.txt` → CLI → fonte crua do pacote → web → offline**. Doc offline é a última parada porque é uma foto com data: envelhece sem avisar. Nenhuma lib entra com menos de duas fontes.

Catálogo completo em [`docs/fontes.yaml`](docs/fontes.yaml); a regra, em [`.claude/rules/documentacao.md`](.claude/rules/documentacao.md). `just fontes` reprova quem violar.

<!-- /gerado:docs -->
---

As seções entre marcadores `<!-- gerado:… -->` são saída de `just readme`. Para mudar
o que elas dizem, mude a fonte de verdade; `just check` reprova o README desatualizado.
