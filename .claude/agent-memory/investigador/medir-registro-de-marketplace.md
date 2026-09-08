---
name: medir-registro-de-marketplace
description: "Verificado — `claude plugin marketplace list` não processa `extraKnownMarketplaces`; quem processa é o startup. Medidor correto, sem custo de API. Claude Code 2.1.233."
metadata:
  type: reference
---

**Procedência:** sessão principal, 2026-08-17. Ver
`docs/ai-log/EP-001-medidor-reprovava-o-controle.md`.

**Verificado em 2026-08-17, Claude Code 2.1.233.** `claude plugin marketplace list`
devolve `No marketplaces configured` mesmo quando o `.claude/settings.json` do projeto
declara um marketplace e a pasta tem trust — **inclusive com path absoluto**, que é o
caso que tinha obrigação de passar. O subcomando não processa `extraKnownMarketplaces`.

Quem processa é o **startup de uma sessão**. E o registro acontece **antes** da checagem
de login, então dá para medir sem gastar chamada de API:

```bash
CFG=/tmp/cfg-spike; rm -rf "$CFG"; mkdir -p "$CFG"
cat > "$CFG/.claude.json" <<JSON
{ "hasCompletedOnboarding": true,
  "projects": { "$PWD": { "hasTrustDialogAccepted": true } } }
JSON
CLAUDE_CONFIG_DIR="$CFG" claude -p --model haiku "oi" < /dev/null   # → Not logged in
jq -c . "$CFG/plugins/known_marketplaces.json"                      # ← a medição real
```

| Onde olhar | O que significa |
|---|---|
| `$CFG/plugins/known_marketplaces.json` | O marketplace foi **registrado** |
| `$CFG/plugins/installed_plugins.json` | Fica `{"version":2,"plugins":{}}` para plugin in-repo — ele é carregado **in-place**, não "instalado" |

> **Legenda.** *Registrado* = o Claude conhece o catálogo. *Instalado* = há cópia no cache
> de plugins. Plugin com source relativo funciona sem estar instalado, então
> `installed_plugins.json` vazio **não** é sinal de falha.

**Corolário:** `claude plugin list` também não lista plugin in-repo mesmo funcionando
(verificado em 2026-08-14). Para "o plugin carrega?", só teste funcional serve — invocar
o comando ou a skill e comparar com um token único.

**Sem `< /dev/null`** o `claude -p` espera stdin e avisa
`no stdin data received in 3s`, atrasando cada caso.

Ver [[marketplace-in-repo-path-relativo]] (o achado que este medidor quase enterrou) e
[[spike-precisa-de-caso-de-controle]] (o que pegou o erro).
