# Memória do Investigador — core-api-dart

## Plugins e distribuição do toolbox
- [Toolbox in-repo por `extraKnownMarketplaces` relativo](marketplace-in-repo-path-relativo.md) — verificado: `"path": "."` registra depois do trust; exige abrir o Claude na raiz.
- [Como medir se um marketplace foi registrado](medir-registro-de-marketplace.md) — `plugin marketplace list` **não** processa o campo; quem processa é o startup.

## Ambiente e isolamento de spike
- [`CLAUDE_CONFIG_DIR` isolado](config-dir-isolado-para-spike.md) — o `.claude.json` mora dentro dele (dá para semear trust), mas não herda o login.

## Método de investigação
- [Spike sem caso de controle mente](spike-precisa-de-caso-de-controle.md) — 4 casos reprovaram juntos por medidor quebrado, não por hipótese falsa.
