---
name: marketplace-in-repo-path-relativo
description: "Verificado — `extraKnownMarketplaces` com `{\"source\":\"directory\",\"path\":\".\"}` registra o marketplace depois do trust; falha se o Claude abrir numa subpasta. Claude Code 2.1.233."
metadata:
  type: reference
---

**Procedência:** achado da sessão principal em 2026-08-17, não de uma investigação deste
agente. Narrado em `docs/ai-log/EP-001-medidor-reprovava-o-controle.md`. Você está
herdando — se for afirmar, o rótulo passa a ser seu.

**Verificado em 2026-08-17, Claude Code 2.1.233, macOS 26.5.1 arm64.** Spike de 6 casos
em repositório descartável, cada caso num `CLAUDE_CONFIG_DIR` novo (ver
[[config-dir-isolado-para-spike]]).

Um marketplace declarado no `.claude/settings.json` do projeto **com path relativo** é
registrado, desde que a pasta tenha trust:

```json
{
  "extraKnownMarketplaces": {
    "acdg-local": { "source": { "source": "directory", "path": "." } }
  },
  "enabledPlugins": { "acdg-toolbox@acdg-local": true }
}
```

| Caso | trust | `path` | cwd | Registrou? |
|---|:---:|---|---|:---:|
| A | ✗ | `"."` | raiz do repo | ✗ |
| B | ✓ | `"."` | raiz do repo | ✅ |
| C | ✓ | absoluto | raiz do repo | ✅ (controle) |
| D | ✓ (só raiz) | `"."` | subpasta | ✗ |
| E | ✓ (raiz+sub) | `"."` | subpasta | ✗ |
| F | ✓ (raiz+sub) | **absoluto** | subpasta | ✗ |

> **Legenda.** *trust* = `projects[<caminho>].hasTrustDialogAccepted` no `.claude.json`.
> *Registrou?* = o marketplace apareceu em `$CFG/plugins/known_marketplaces.json`, passo
> anterior a carregar o plugin. *C* prova que o medidor funciona; *F* isola a causa da
> falha em subpasta.

**O `"."` é gravado já resolvido para absoluto**, com `installLocation` no próprio
repositório — in-place, sem clone:

```json
{"acdg-local":{"source":{"source":"directory","path":"/…/repo"},
 "installLocation":"/…/repo","lastUpdated":"2026-08-17T16:16:30.138Z"}}
```

**A falha em subpasta não é do path relativo** — o caso F mostra que o absoluto falha
igual. A causa é o `.claude/settings.json` do projeto não ser aplicado quando a sessão
abre numa subpasta, o mesmo motivo pelo qual o `CLAUDE.md` deste repositório manda abrir
na raiz. Não "conserte" isso trocando para path absoluto: não resolve e perde a
versionabilidade.

**Documentado** (`docs/offline-reference/claude-code/_full.txt:32569`, versão baixada em
2026-08-17): path relativo em source `directory`/`file` resolve contra o *main checkout*
do repositório, e o estado de marketplace é por usuário, em
`~/.claude/plugins/known_marketplaces.json` — **não** por projeto. Consequência: um spike
que registra marketplace suja o estado global se não for isolado.

⚠️ **`"path"` absoluto obrigatório é regra de `strictKnownMarketplaces`, não de
`extraKnownMarketplaces`.** O `_full.txt:79251` diz "required: absolute path" dentro da
seção de `strictKnownMarketplaces` (heading em `_full.txt:79141`). Ler aquela linha fora
do contexto leva à conclusão errada de que relativo não é aceito.

**Ainda inferido, não verificado:** que a *skill/comando* do plugin responde por essa
via. Este spike mediu o **registro**; um spike de 2026-08-14 mediu o **carregamento** de
plugin com source relativo (marketplace registrado por comando). A composição é
inferência forte — fechar exige sessão **com login** na pasta.

Ver [[medir-registro-de-marketplace]] para não repetir o erro de instrumento.
