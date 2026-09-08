# Diário de Bordo da IA

O diário vive na **wiki do versionador**, publicado automaticamente a cada `git push`.
Não vive no código, não vive em `docs/`.

## As três camadas

| Camada | O quê | Onde | Vai pro Git? |
|--------|-------|------|--------------|
| Captura bruta | Todo prompt (hook `UserPromptSubmit`) e toda resposta ao `AskUserQuestion` (hook `PostToolUse`) | `.ai-log/raw-prompts.md` | ❌ gitignored |
| Publicação | Uma página por push: commits enviados + prompts do período | wiki | ❌ repositório separado |
| Regra permanente | O que vale sempre | `.claude/rules/` | ✅ |

> **Legenda.** A *captura bruta* é matéria-prima local, com caminhos e trechos colados.
> A *publicação* é o recorte que vai para a wiki. Confundir as duas põe ruído de sessão
> no histórico do produto.

## Automação

`just diario` monta a página e publica na wiki; `just diario-seco` mostra sem publicar.
O hook `pre-push` (`.githooks/pre-push`) dispara no push, e `just hooks-git` o instala.

Sem `origin` configurado, o script avisa e sai sem bloquear o push.

## O que não vai para a wiki

Segredo. O redator do harness substitui credencial por `[REDIGIDO]` na captura bruta,
mas a proteção é do arquivo, não do terminal — se o aviso de detecção aparecer, rotacione
a chave (ver `segredos.md`).

`[NOLOG]` em qualquer posição do prompt impede o registro daquele prompt.

## Registre também quando a IA erra

Um diário em que a IA nunca erra não ensina nada a quem for ler depois. O que interessa é
o sintoma que denunciou o erro e a correção de rumo.
