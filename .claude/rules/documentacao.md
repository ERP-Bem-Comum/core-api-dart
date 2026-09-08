# Fontes de documentação

Documentação offline **não é o primeiro caso**. Ela é o último — o que sobra quando
nada vivo responde. Uma cópia baixada envelhece em silêncio e é citada meses depois já
falsa; é exatamente o modo de falha que `verificacao.md` chama de "achado sem versão".

## A cascata de prioridade

Ao precisar da documentação de uma biblioteca, ferramenta ou serviço, tente **nesta
ordem** e pare na primeira que responder:

| # | Tipo | Chave no catálogo | O que é |
|---|------|-------------------|---------|
| 1 | **MCP** | `mcp` | Servidor MCP que serve a doc como ferramenta — resposta viva, já recortada |
| 2 | **`llms.txt`** | `llms-txt` | Índice/dump que o projeto publica **para LLM**, sem HTML no meio |
| 3 | **CLI (doc)** | `cli` | O próprio binário documenta: `--help`, `help <sub>`, `dart doc`, `man` |
| 4 | **Fonte crua** | `raw-source` | O `.md`/dartdoc dentro do pacote instalado — o que **esta** versão diz |
| 5 | **Web** | `web-fetch` | `WebFetch`/`WebSearch` na doc oficial |
| 6 | **Offline** | `offline` | Cópia baixada em disco. **Só quando as cinco acima falharem** |

> **Legenda.** A ordem é de *frescor e precisão decrescentes*. O MCP responde a
> pergunta; o `llms.txt` entrega o texto certo sem ruído; a CLI e a fonte crua dizem o
> que a **versão instalada** faz, não o que a documentação do site diz da versão mais
> nova; a web é o site oficial em tempo real; o offline é uma foto com data.

**A cascata é de tentativa, não de qualidade absoluta.** Para saber o que a versão
instalada faz — assinatura de método, default de parâmetro —, `raw-source` (4) ganha de
qualquer coisa acima dela. Ao pular a ordem, diga por quê.

## Duas fontes, no mínimo, por biblioteca

Nenhuma biblioteca entra no projeto com **uma** fonte de documentação só. Uma fonte
única é um ponto de falha: sai do ar, muda de URL, ou está desatualizada, e não há como
perceber — não existe com o que confrontar.

Toda lib usada vai para `docs/fontes.yaml` com **duas ou mais** entradas. O portão
reprova quem tiver menos (`just fontes`).

Para pacotes Dart isso é quase de graça: o MCP `dart` já dá `pub_dev_search` (1) e
`rip_grep_packages` / `read_package_uris` sobre o pacote instalado (4).

## Toda pasta de doc se apresenta

`docs/` e cada pasta de **primeiro nível** sob ela têm, na raiz, um **`_FONTES.md`** — o
arquivo de redirecionamento. Subpasta herda o índice do pai; exigir um por nível
transformaria dump gerado em obrigação de curadoria. Se uma subpasta é grande o
bastante para o índice do pai não descrevê-la, dê a ela o seu.
Ele existe para que um agente que entra na pasta descubra, sem varrer nada, **que tipos
de documentação existem ali e para onde apontam**.

Um `_FONTES.md` diz, curto:

- o que essa pasta cobre, e o que ela **não** cobre;
- que tipos de fonte existem para esse assunto, na ordem da cascata;
- para onde ir quando a resposta não está ali.

O portão reprova área de documentação sem `_FONTES.md`.

## O catálogo

`docs/fontes.yaml` é a **fonte única** do mapa lib × documentação. Formato YAML porque
o "por quê" de cada fonte é comentário, não campo — e porque é o formato nativo do
ecossistema Dart.

```yaml
- nome: shelf                 # identificador da lib/ferramenta
  usada_para: HTTP server     # por que está no projeto
  fontes:
    - tipo: mcp               # um dos: mcp, llms-txt, cli, raw-source, web-fetch, offline
      onde: "mcp__dart__pub_dev_search"
      nota: "busca no pub.dev; não traz o corpo da doc"
    - tipo: raw-source
      onde: "package:shelf/  (via mcp__dart__rip_grep_packages)"
```

Campos: `nome`, `usada_para`, `fontes[]` com `tipo` (do enum), `onde` (comando, URL ou
caminho) e `nota` opcional. `just fontes` valida.

## Skills não são documentação — e as duas andam juntas

Skill **não entra na cascata acima** e **não conta** como uma das duas fontes. Ela
responde a outra pergunta, e confundir as duas é erro de categoria:

| | Documentação de package | Skill |
|---|---|---|
| **Responde** | *o que esta versão faz* | *como fazer isto bem, aqui* |
| **Natureza** | fixa à versão — só muda quando a versão muda | viva — muda com o contexto e a prática |
| **Autoridade** | o artefato instalado; é **contrato** | quem escreveu a **prática** (autor da lib, ou nós) |
| **Customização local** | seria adulteração | é **esperada**: `skills@ get` pergunta se sobrescreve a sua |
| **Como se verifica** | abrir o pacote, rodar a CLI, comparar assinatura | não se verifica; julga-se pelo resultado |

> **Legenda.** *Contrato* é o que o código aceita e devolve — dá para provar abrindo o
> pacote. *Prática* é o bom uso desse contrato: por que preferir um padrão, quais são os
> anti-padrões. Nenhum comando prova uma prática.

**As três regras que decorrem disso:**

1. **A skill guia a ação; a documentação confirma o contrato antes de commitar.** Skill
   sem doc é seguir um padrão que a sua versão talvez não suporte. Doc sem skill é ter a
   API sem saber o que dá errado com ela.
2. **Em divergência, a versão instalada ganha.** A skill pode estar à frente ou atrás do
   pacote que você tem. Se ela manda usar algo que não existe no artefato, a errada é ela.
3. **Skill nunca sustenta o rótulo "verificado"** (`verificacao.md`). Sendo prática
   mutável, não é nem fonte canônica — para afirmar comportamento, abra o pacote ou rode
   o comando.

### Skill da lib antes de skill nossa

Quando o autor do pacote publica uma skill, **use a dele**. Escrever a nossa por cima
duplica manutenção e envelhece calada: a lib evolui, a prática dela evolui junto, e a
nossa cópia fica descrevendo um mundo que acabou. Skill própria é para o que é **nosso** —
convenção deste domínio, deste harness —, não para reexplicar biblioteca alheia.

### As duas camadas de skill, e onde cada uma mora

| Camada | Origem | Onde mora | Escopo |
|--------|--------|-----------|--------|
| Linguagem/framework | plugin `dart-flutter` (`flutter/agent-plugins`) | fora do repositório | máquina (`user`) |
| Package | `dart run skills@ get` (`just skills`) | `.agents/skills/` + `.config/dart_skills/` | este projeto |
| Nossa | escrita à mão | `.claude/skills/` | este projeto |

> **Legenda.** `.agents/` é o diretório **neutro de fornecedor** que o Dart adotou — serve
> Claude Code, Cursor, Copilot e outros. `.claude/` é só nosso. Skill de package **não**
> vai para `.claude/skills/`: ela é gerada, e misturar gerado com escrito à mão faz
> perder de vista o que se pode reescrever.

**As duas pastas do projeto são versionadas.** Skill é mutável por natureza: se ficar
fora do Git, a customização local se perde na primeira máquina nova e a atualização de
uma skill de lib entra sem ninguém revisar. Versionada, ela aparece como diff no PR —
que é o único momento em que alguém repara que a prática mudou.

## O que isso muda no que já existe

`docs/offline-reference/` continua existindo — como **fallback declarado**, posição 6,
nunca como primeira parada. `just refs-claude` repopula quando preciso e carimba a data.
Doc offline sem data de download é inutilizável: não dá para saber o que ela perdeu.
