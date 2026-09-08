# Regressão zero, e o trabalho alheio

## Não existe "o erro não é meu"

Qualquer vermelho que apareça na sessão — teste, `dart analyze`, `dart format`, hook,
build, `just check` — é tratado como **regressão a corrigir agora**, tenha ou não sido
causado pela mudança atual.

| ❌ Nunca | ✅ Sempre |
|---------|----------|
| "esse trecho não é meu, não vou mexer" | Corrigir, ou escalar com a causa-raiz nomeada |
| "não conheço esse código nesta sessão" | Ler o código e corrigir |
| "já estava quebrado antes" | Irrelevante. Está quebrado agora, na sua sessão |
| "não toquei nessa parte" | Idem |
| Marcar `skip` para o vermelho sumir | Consertar a causa, ou corrigir o portão mal classificado **e provar o verde no caminho certo** |
| `// ignore:` / `// ignore_for_file:` para calar o analyzer | Corrigir o código, ou mudar o lint no `analysis_options.yaml` — **dizendo que está mudando** |

### Suprimir diagnóstico é contornar o portão

`// ignore: <código>`, `// ignore_for_file: type=lint` e `# ignore:` no `pubspec.yaml`
apagam o vermelho sem consertar nada, e apagam **em silêncio**: some da saída do
`dart analyze`, some do CI, e ninguém revisa de novo.

⚠️ **A skill `dart-flutter:dart-run-static-analysis` recomenda exatamente isso** — a
seção *Diagnostic Suppression* ensina as quatro formas de suprimir. A skill não está
errada para o ecossistema em geral; ela **não vale aqui**, e essa precedência está em
`documentacao.md`: skill é prática, e a prática deste repositório é a regra acima.

A exceção é o que já está no `analysis_options.yaml`: `exclude:` para código **gerado**
(`*.g.dart`, `*.freezed.dart`). Arquivo gerado não se conserta — se conserta o gerador.

Diante de um vermelho existem exatamente **três saídas legítimas**:

1. **Consertar a causa** — volta ao verde de verdade.
2. **Corrigir o portão mal classificado** — e então *provar* o verde no caminho certo.
3. **Escalar ao Gabriel** com a causa-raiz explícita — nunca em silêncio.

## Nunca reverter trabalho alheio sem consultar

Código que você não escreveu — nesta sessão ou em qualquer outra — **não se reverte,
não se apaga e não se reescreve por conta própria**.

Se um trecho parece errado, obsoleto ou atrapalha:

1. Diga o que encontrou e por que parece problemático.
2. **Pergunte antes de agir.**
3. Só então altere.

Vale para código, configuração, documentação e histórico. *"Isso não é meu, vou
reverter"* é a única frase mais grave que *"isso não é meu, não vou mexer"*.

## O portão não se contorna

O hook `Stop` roda `just check` quando há mudanças no working tree. Se ele bloquear:

- **Não** desligue o hook para seguir.
- **Não** limpe o working tree para escapar do gatilho.
- **Não** adicione exceção ao portão sem dizer que está adicionando.

Um portão que se contorna quando incomoda não é portão — é decoração que custa tempo.
