# `docs/` — o que existe aqui

Arquivo de redirecionamento da raiz da documentação. A regra que governa tudo abaixo é
`.claude/rules/documentacao.md`.

## A cascata, em uma linha

**MCP → `llms.txt` → CLI → fonte crua do pacote → web → offline.** Documentação offline
é a **última** parada, nunca a primeira.

## O que há nesta pasta

| Caminho | Tipo | Conteúdo |
|---------|------|----------|
| `fontes.yaml` | catálogo | Mapa **lib × onde ler sobre ela**. Fonte única. Toda lib com ≥ 2 fontes |
| `offline-reference/` | fallback | Cópias baixadas (Claude Code, Claude API). **Gitignored**, posição 6 da cascata |

> **Legenda.** *Catálogo* é dado estruturado que o portão valida. *Fallback* só se
> consulta depois que as cinco fontes vivas falharam.

## O que **não** está aqui

- **Regras de trabalho** → `.claude/rules/`.
- **Diário de bordo** → wiki do versionador, publicado a cada push (`just diario`).
  Captura bruta em `.ai-log/`, gitignored.
- **Decisão e o porquê dela** → wiki. Não em código, não aqui (`.claude/rules/comentarios.md`).
- **O que vale da próxima vez** → `.claude/agent-memory/<agente>/`.
- **Comandos do repositório** → `just --list`.
- **Documentação de domínio do ERP** → ainda não existe. Não crie por antecipação.

## Antes de adicionar pasta aqui

Toda pasta de primeiro nível sob `docs/` precisa de um `_FONTES.md` na raiz — `just
fontes` reprova quem não tiver. E toda lib nova entra em `fontes.yaml` com duas fontes
ou mais.
