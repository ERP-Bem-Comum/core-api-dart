---
name: config-dir-isolado-para-spike
description: "Verificado — `CLAUDE_CONFIG_DIR` guarda o próprio `.claude.json` dentro dele (dá para semear trust em headless), mas não herda o login. Claude Code 2.1.233."
metadata:
  type: reference
---

**Procedência:** sessão principal, 2026-08-17. Ver
`docs/ai-log/EP-001-medidor-reprovava-o-controle.md`.

**Verificado em 2026-08-17, Claude Code 2.1.233, macOS 26.5.1 arm64.** É a forma de rodar
spike de configuração sem tocar o estado do Gabriel — necessário porque marketplace e
plugin são estado **por usuário**, não por projeto.

| Fato | Consequência |
|---|---|
| O `.claude.json` mora **dentro** do config dir (`$CFG/.claude.json`) | Dá para semear `projects[<caminho>].hasTrustDialogAccepted: true` e simular trust em headless, sem editar o `~/.claude.json` real |
| O config dir isolado **não herda o login** | No macOS a credencial não vem do Keychain para um dir novo: toda sessão termina em `Not logged in · Please run /login`. Teste **funcional** (skill/comando respondendo) não roda por aqui |
| `$CFG/plugins/` recebe `known_marketplaces.json` e `installed_plugins.json` | É onde se mede o efeito, ver [[medir-registro-de-marketplace]] |

> **Legenda.** *Semear* = escrever o arquivo de config antes de rodar, para que a sessão
> comece no estado desejado. *Headless* = `claude -p`, que nunca mostra diálogo de trust.

**Em headless o trust não pode ser concedido interativamente** — a própria mensagem de
erro do Claude Code diz o que fazer, e nomeia o caminho **dentro** do config dir:

```
Ignoring 8 permissions.allow entries from .claude/settings.json: this workspace has not
been trusted. … or set projects["/Users/…/core-api-dart"].hasTrustDialogAccepted: true
in /…/scratchpad/spike-mkt/cfg/.claude.json
```

**Não edite o `~/.claude.json` real por fora.** O processo do Claude Code reescreve o
arquivo inteiro (mantém backups em `$CFG/backups/`), então uma edição externa pode ser
atropelada ou perdida. Se o spike precisa de login, o caminho é uma sessão interativa do
Gabriel, não uma edição da config dele.

⚠️ **Rodar `claude -p` com o cwd dentro deste repositório dispara os hooks do projeto** —
o `UserPromptSubmit` gravou o prompt do subprocesso no `.ai-log/raw-prompts.md`, poluindo
o diário bruto com prompt que não é de pessoa. Rode spikes com `cd` para a pasta
descartável, sempre.

**Observado, não isolado:** esse hook rodou num config dir onde o workspace **não** tinha
trust (a mesma execução avisou que estava ignorando `permissions.allow` por falta de
trust). Se hooks de `settings.json` de projeto ignoram trust em geral, é achado de
segurança — mas falta caso de controle. **Não afirme sem testar.**
