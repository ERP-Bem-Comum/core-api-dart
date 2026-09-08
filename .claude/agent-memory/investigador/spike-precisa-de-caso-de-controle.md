---
name: spike-precisa-de-caso-de-controle
description: "Suposição derrubada — 4 casos reprovando juntos parecia hipótese falsa; era o medidor quebrado. Todo spike precisa de um caso que tem obrigação de passar."
metadata:
  type: reference
---

**Procedência:** erro cometido na sessão principal em 2026-08-17, narrado em
`docs/ai-log/EP-001-medidor-reprovava-o-controle.md`.

Um spike de 4 casos reprovou os 4. A leitura natural — "a hipótese é falsa" — estava
errada: o **medidor** não media (ver [[medir-registro-de-marketplace]]). O que denunciou
foi um caso de controle, com path absoluto, que *tinha obrigação de passar* e não passou.

**A regra que sobra:** todo spike leva ao menos um caso cujo resultado esperado é
**sucesso**. Os casos que testam a hipótese não conseguem distinguir estas duas coisas:

| Sintoma | Hipótese falsa | Medidor quebrado |
|---|---|---|
| Casos da hipótese reprovam | ✔ | ✔ |
| Caso de controle reprova | ✗ | ✔ |

> **Legenda.** *Caso de controle* = combinação que, se a ferramenta funciona como
> documentado, **tem** que dar verde. Ele não testa a pergunta; testa o instrumento.

**Segunda regra, do mesmo spike:** quando duas causas explicam a mesma falha, o desempate
é **um caso a mais**, não uma interpretação mais convincente. Um caso falhou rodando de
subpasta, e "o path relativo resolve contra o cwd" soava óbvio — era falso. Trocar o path
por absoluto (mantendo a subpasta) reproduziu a falha e mostrou que a causa era outra:
o settings do projeto nem era aplicado.

**Por que isso é fácil de errar aqui:** um falso negativo assim passa pelos três rótulos
de `verificacao.md` sem disparar alarme. Havia comando, havia saída literal colada, havia
versão — e a conclusão era errada. O rótulo **verificado** cobre "eu rodei e vi", não
"o que eu rodei mede o que eu afirmo".

Aplique o teste de `verificacao.md` ao próprio instrumento: *existe alguma leitura em que
esta saída significa outra coisa?* Se o comando nunca produziu verde em nenhuma condição,
você não sabe se ele é capaz de produzir verde.
