---
name: wiki-do-versionador
description: Publicar e revisar páginas na wiki do GitHub deste projeto. Use ao escrever decisão, glossário, ADR ou diário na wiki, ao montar link entre páginas, ao nomear arquivo de página, ou ao investigar por que uma página não aparece / um link aponta para lugar errado.
---

# A wiki do versionador

A wiki **não é um recurso com API** — é um repositório Git com um renderizador
na frente. Toda escrita passa por `git`, e as armadilhas abaixo vêm de o
renderizador não ser o mesmo do resto do GitHub.

Endereço: `git@github.com:ERP-Bem-Comum/core-api-dart.wiki.git`.

## Como publicar

**Pelo harness, que é o caminho normal.** `just diario` monta a página do
período e publica; o hook `pre-push` faz isso sozinho a cada `git push`. Não
escreva página de diário à mão.

**À mão, para uma página de conteúdo:**

```
git clone git@github.com:ERP-Bem-Comum/core-api-dart.wiki.git
# escreva o .md, commit, push
```

Não há pull request, revisão nem proteção de branch na wiki: o push é a
publicação. Releia antes de empurrar, porque não há segunda barreira.

**O branch da wiki é `master`, não `main`.** Um workflow ou script que assuma
`main` erra o alvo.

**Sempre `git pull --rebase` antes do push.** O harness publica o diário por um
clone próprio em `~/.cache/core-api-dart-wiki`, então o seu clone fica atrás sem
aviso — o push é rejeitado com `fetch first` no pior momento, depois do texto
pronto.

## As cinco armadilhas

Medidas em 2026-09-08 contra o GitHub em produção, publicando uma página de
spike e lendo o HTML renderizado. Todas contrariam a intuição, e três
contrariam a documentação oficial.

**1. `[[A|B]]` aponta para `B`, não para `A`.** O primeiro campo é o *texto*,
o segundo é o *alvo* — o inverso do MediaWiki e o inverso do que a doc do
GitHub sugere. `[[Spike-Subpagina|a subpágina]]` gerou texto
`Spike-Subpagina` e destino `/wiki/a-subpágina`, uma página que não existe.

> Prefira o link Markdown relativo — `[Decisões](Decisoes)` —, que resolve
> certo e não tem ordem para errar.

**2. Nota de rodapé não existe aqui.** `[^1]` sai como texto literal na
página, embora funcione em README e issue. Use link ou parêntese.

**3. Subpasta é achatada.** `spike/Pagina.md` responde em `/wiki/Pagina`;
`/wiki/spike/Pagina` devolve 302 para `/wiki/spike`. O namespace de títulos é
plano e globalmente único — dois arquivos de mesmo nome em pastas diferentes
colidem. **Organize por prefixo no nome** (`Arq-Decisoes.md`), nunca por pasta.

**4. Hífen no arquivo vira espaço no título.** `Spike-Capacidades.md` aparece
como *"Spike Capacidades"*. Espaço e `/` no nome do arquivo tornam a página
inacessível pela web — **acento, não**: `Decisões.md` responde em 200 e exibe
*"Decisões"*. Nomeie a página em PT-BR acentuado, como manda `idioma.md`.

**5. O repositório da wiki não existe até a primeira página ser criada pela
interface web.** Com a wiki habilitada, o `git clone` ainda devolve
`Repository not found`. Não há como contornar por CLI — não existe `gh wiki`
nem endpoint REST.

## O que renderiza

| Recurso | Situação |
|---------|----------|
| Mermaid em bloco ```mermaid | **renderiza** — não carregue biblioteca |
| `> [!NOTE]` e `> [!WARNING]` | **renderiza** como alerta |
| Lista de tarefas `- [x]` | **renderiza** com caixa |
| Tabela e realce de sintaxe Dart | **renderiza** |
| `_Sidebar.md` e `_Footer.md` | **aparecem**, e são editáveis por git |
| Nota de rodapé `[^1]` | **não** — texto literal |

> **Legenda.** "Renderiza" significa medido no HTML servido pelo GitHub, não
> lido na documentação. A linha de negativo é a que mais importa: é a que faz
> uma página parecer certa no editor e sair errada publicada.

## Antes de publicar, três conferências

1. **Segredo.** A wiki é pública e não tem o redator do harness na frente. Ela
   é a superfície menos protegida do repositório — não cole log, payload nem
   trecho de terminal sem reler.
2. **Nome do arquivo.** Sem espaço, sem `/`, prefixo em vez de pasta.
3. **Links.** Markdown relativo. Se usar `[[…|…]]`, o alvo é o segundo campo.

## O que ainda não foi medido

O evento `gollum` dispara GitHub Actions quando alguém edita uma página, e um
workflow pode dar checkout da wiki com `repository: <owner>/<repo>.wiki` — as
duas coisas são **documentadas**, não verificadas aqui. É o caminho para um
portão tardio da wiki (link quebrado, página órfã, segredo colado). Ao
construí-lo, meça e atualize esta seção.
