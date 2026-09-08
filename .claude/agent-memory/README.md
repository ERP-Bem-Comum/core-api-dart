# Memória dos agentes

Cada subagente com `memory: project` no front-matter tem uma pasta aqui, criada com o
nome dele. O conteúdo é **versionado no Git** — é o único mecanismo de memória que é ao
mesmo tempo escrito pelo agente e compartilhável entre pessoas.

```
.claude/agent-memory/
  investigador/
    MEMORY.md              ← índice enxuto: uma linha por entrada
    hooks-armadilhas.md    ← um arquivo por fato
```

## O formato

`MEMORY.md` é **índice**, não conteúdo:

```markdown
# Memória do Investigador — core-api-dart

## Postgres
- [SKIP LOCKED na fila de outbox](outbox-skip-locked.md) — medido: 3 workers, zero duplicata.

## Suposições derrubadas
- [Isolate não acelera I/O](isolate-io-derrubado.md) — port ficou 12% mais lento.
```

Cada arquivo de tópico leva front-matter:

```markdown
---
name: outbox-skip-locked
description: <uma linha — é o que decide se vale abrir>
metadata:
  type: reference
---

O fato, com a **versão** da ferramenta e como foi verificado.
Ligações para outros arquivos com [[nome-do-arquivo]].
```

## Os limites que mordem

| Limite | Consequência |
|--------|--------------|
| `MEMORY.md` entra no prompt do agente até **200 linhas ou 25 KB** | O excedente é **descartado sem aviso**. Índice enxuto não é estética |
| Arquivos de tópico **não** carregam no startup | São lidos sob demanda — pode escrever à vontade |
| A memória de um agente **não** é vista por outro | Cada papel carrega só a sua |
| Desligar auto memory (`autoMemoryEnabled: false` ou `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`) **anula o campo `memory:` inteiro** | E não avisa. Se um agente parar de lembrar, verifique isso primeiro |

## O que guardar

- Comportamento de ferramenta **com versão** — sem versão, envelhece em silêncio.
- Armadilha de ambiente que custou tempo.
- Decisão e **o motivo** dela.
- **O que se provou falso.** Vale tanto quanto o que se confirmou, e impede que a
  suposição volte.

## O que não guardar

O que o repositório já registra: estrutura de código, histórico do Git, o que está no
`CLAUDE.md` ou nas regras. Memória duplicada diverge, e a cópia errada é a que alguém
vai ler.
