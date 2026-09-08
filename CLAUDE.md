# CLAUDE.md — core-api-dart

Backend Dart do **bem_comum** (ERP Financeiro): monolito modular em pub workspaces,
um package por bounded context, arquitetura hexagonal, fatia vertical primeiro.
Banco: **PostgreSQL 18** — decisão fechada, com o backbone de eventos e jobs no
próprio banco (outbox, `SKIP LOCKED`, `LISTEN/NOTIFY`, `pg_cron`).

## Inicie o Claude na raiz deste repositório

`.claude/settings.json` **não é herdado de diretórios-pai** — diferente do `CLAUDE.md`,
que é. Uma sessão aberta dentro de `packages/<bc>/` roda **sem** as permissões, sem os
hooks e sem o portão deste arquivo. Se precisar trabalhar num package, abra na raiz e
navegue de lá.

## Tarefas

Toda tarefa repetitiva é uma receita no `Justfile`. Rode `just --list` para descobrir
o que existe — não invente comando solto nem o documente fora dali.

- **`just check` é o portão.** Rode antes de considerar qualquer trabalho pronto, e
  **mostre a saída** em vez de afirmar que passou.
- Um hook `Stop` roda o portão quando o working tree está sujo. Se ele bloquear, o
  vermelho é real: conserte, não contorne.
- O CI (`.github/workflows/ci.yml`) chama **a mesma receita** — `just check`. Nunca
  liste comandos soltos no YAML: duas definições de verde divergem em silêncio.
- **Não edite à mão as seções `<!-- gerado:… -->` do `README.md`.** Elas são saída de
  `just readme`; para mudar o que dizem, mude a fonte de verdade (`Justfile`,
  `docs/fontes.yaml`, a tabela de regras abaixo, `packages/*/pubspec.yaml`). O hook
  `Stop` regenera e `just check` reprova a divergência. A prosa fora dos marcadores
  é humana e nunca é tocada.

## Documentação: offline é a última parada

Ao consultar qualquer biblioteca, siga a cascata **MCP → `llms.txt` → CLI → fonte crua
do pacote → `WebFetch` → offline**. Toda lib usada tem **duas fontes ou mais** em
`docs/fontes.yaml`, e toda pasta sob `docs/` tem um `_FONTES.md` de redirecionamento.
Detalhe em `.claude/rules/documentacao.md`; o portão verifica (`just fontes`).

**Skill não é documentação.** Doc é contrato, fixo à versão; skill é prática, viva e
mutável. As duas andam juntas — a skill guia a ação, a doc confirma o contrato — mas
skill não conta como fonte e nunca sustenta o rótulo "verificado". Ao adicionar
dependência, rode `just skills`: skill publicada pela lib vem antes de escrever a nossa.

## As três regras que não têm exceção

**Verifique antes de afirmar.** Rode o comando e cole a saída. Toda afirmação vem
rotulada como **verificado** (rodou/leu), **documentado** (a fonte afirma, você não
testou) ou **inferido** (sua leitura, pode estar errada). Afirmação sem rótulo é
inútil, porque quem lê não sabe quanto confiar.

**Todo vermelho na sessão é regressão a corrigir agora** — tenha ou não sido causado
pela mudança atual. Não existe "o erro não é meu".

**Código alheio não se reverte sem consultar.** Diga o que encontrou, pergunte, e só
então altere.

## Onde estão as regras

Este arquivo carrega **inteiro, em toda sessão** — por isso é curto de propósito. O
detalhe vive em `.claude/rules/`:

| Arquivo | Assunto |
|---------|---------|
| `verificacao.md` | Os três rótulos, e o que conta como prova |
| `regressao-zero.md` | Vermelho é regressão · não reverter trabalho alheio |
| `dart-style.md` | **Dart de sabor Swift** — imutabilidade, `sealed`, `Result`, isolates |
| `documentacao.md` | Cascata de fontes · duas fontes por lib · `_FONTES.md` por pasta |
| `comentarios.md` | **Só dartdoc sobre estrutura** · config diz o quê, nunca o porquê |
| `idioma.md` | Código em EN, texto para pessoas em PT-BR |
| `segredos.md` | Convenção `[SECRET:NOME]` e `[NOLOG]` |
| `diario-de-bordo.md` | Diário na wiki, publicado a cada push |

Regras com `paths:` no front-matter só carregam quando você **lê** um arquivo que casa
com o glob — e **não sobrevivem à compactação**. Por isso o que não pode sumir está
aqui em cima, não numa regra condicional.

## Estado do repositório

O código de aplicação ainda **não existe**. O que está montado é o harness: regras,
hooks de registro, portão e memória de agentes. Não escreva comando de execução em
documentação antes de tê-lo executado.
