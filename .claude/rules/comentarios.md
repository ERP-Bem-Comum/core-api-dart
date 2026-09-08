# Comentários

**Se você precisa explicar o motivo de uma decisão dentro do arquivo, o código ainda não
está bom.** Código explica o próprio comportamento; documentação explica a estrutura.

## Em Dart: só dartdoc, só sobre uma declaração

Comentário em `.dart` é `///` ancorado a uma declaração — classe, método, campo,
`typedef`. Não existe comentário solto.

| O que cabe no `///` | O que **não** cabe |
|---------------------|--------------------|
| O que a declaração é ou faz | Por que foi decidida assim |
| Cada parâmetro e o que ele significa | Ressalva, alerta, aviso ao futuro |
| O retorno, e os erros que emergem | Histórico, alternativa descartada |
| No máximo **um** exemplo de uso | Narrativa de qualquer tipo |

> **Legenda.** *Ancorado a uma declaração* significa que o `///` vem imediatamente antes
> de algo que o compilador enxerga. Um bloco de prosa entre funções, ou um cabeçalho
> narrando o arquivo, não documenta estrutura nenhuma — é diário.

`//` em código Dart é proibido, incluindo `// ignore:` (ver `regressao-zero.md`).

Se o comportamento de um trecho precisa de explicação, o conserto é **nome, extração de
função ou tipo** — nunca uma frase acima da linha.

## Em configuração: diga o QUÊ, nunca o PORQUÊ

Vale para `pubspec.yaml`, `analysis_options.yaml`, `Justfile`, workflows, `.gitignore`,
scripts. Comentário só quando descreve **o que a linha faz** e isso não é óbvio pelo
nome. Justificativa, trade-off e "de propósito" não entram.

```yaml
# ✅  Ordem alfabética exigida por `sort_pub_dependencies`.
# ❌  A escolha por `lints` em vez de um pacote de terceiros é deliberada: o
#     conjunto acompanha o SDK e não traz opiniões que conflitem com o estilo.
```

## Onde mora o que foi expulso

| Conteúdo | Destino |
|----------|---------|
| Por que a decisão foi tomada | Wiki do versionador |
| Ressalva, risco, alerta | Discussão com o P.O., ou issue |
| O que aconteceu numa sessão | Wiki — nunca o código, nunca `docs/` |
| Regra permanente de trabalho | `.claude/rules/` |

Prosa dentro do arquivo envelhece e vira ruído: ninguém a revisa quando o código muda,
e ela passa a afirmar com confiança algo que deixou de ser verdade.
