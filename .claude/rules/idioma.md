# Idioma por camada

**O idioma de um artefato é determinado pela camada a que ele pertence: o que a máquina
lê é inglês; o que uma pessoa lê é português.**

## A tabela — fonte única

Esta é a única definição de idioma por camada do repositório. **Não replicar em outro
arquivo** — quem precisar dela aponta para cá.

| Camada | Idioma | Exemplo |
|--------|--------|---------|
| Código: tipos, funções, variáveis, pastas, arquivos | **EN** | `class Partner`, `Money.fromCents`, `packages/partners/lib/` |
| Strings exibidas a pessoas | **PT-BR** | *"Este CNPJ já está cadastrado"* |
| Documentação: `docs/`, `.claude/`, READMEs | **PT-BR** | identificadores sempre entre backticks |
| Dartdoc (`///`) e comentários no código | **PT-BR** | *"Se o contrato já foi assinado."* · referências em `[Colchetes]` ou `` `backticks` `` |
| Diálogo, relatórios, notas de planejamento | **PT-BR com acentuação completa** | *"código"*, nunca *"codigo"* |
| Erros internos (união de literais) | **EN kebab-case** | `'partner-not-found'` |
| Eventos de domínio | **EN no passado** | `ContractSigned`, `PaymentSettled` |
| Migrações e objetos de banco | **EN snake_case** | `partner_id`, `outbox_events` |
| Mensagens de commit | **PT-BR** com escopo de módulo | `feat(partners): adiciona VO de CNPJ` |

> **Legenda.** **Código** é o que um compilador lê — o nome serve a quem mantém, não a
> quem usa. **Strings exibidas** são as frases que chegam ao usuário do ERP. **Erros
> internos** identificam *qual* erro ocorreu e viram `switch`; a frase mostrada é outra
> coisa. **Evento de domínio** nomeia algo que já aconteceu — o passado no nome impede
> que seja tratado como comando.

## As duas regras que se erram na prática

**Nunca traduza um termo de domínio sem registrar a tradução.** O glossário de duas
colunas — termo do negócio × identificador de código — é parte do modelo, não um anexo.
Termo que só existe de um lado é termo sem dono.

**Escolher a palavra em inglês é decisão de modelo, não de estilo.** Se `Partner` ou
`Counterparty` está em aberto, isso é modelagem de domínio — não se resolve no ato de
escrever o código.

## Dartdoc é prosa para pessoas — logo, PT-BR

O `///` não é lido pelo compilador: é lido por quem mantém, no editor e no `dart doc`.
Cai portanto na regra geral — **texto para pessoas é português** —, e não na exceção dos
identificadores. O pacote não é publicado (`publish_to: none`), o domínio é brasileiro e
a equipe também.

O que **não** muda com o idioma são as convenções de forma, que valem em PT-BR igual:

| Declaração | Forma | Exemplo |
|------------|-------|---------|
| Propriedade, getter | frase **nominal** | `/// O CNPJ normalizado do parceiro, sem pontuação.` |
| Booleano | começa com **"Se"** | `/// Se o contrato já foi assinado por ambas as partes.` |
| Método, função | verbo na **terceira pessoa** | `/// Liquida o pagamento e emite [PaymentSettled].` |

> **Legenda.** *Frase nominal* descreve **o que a coisa é**, não o que o getter faz —
> `/// O raio da esfera.`, nunca *"Obtém o raio…"*. A forma existe para o dartdoc ler
> como uma frase única junto do nome da declaração.

Não repita a assinatura nem o nome do elemento (*"Esta classe é um…"*, *"O método foo
faz…"*). Referência a outro elemento vai em `[Colchetes]`, que o `dart doc` transforma
em link; texto que é código literal vai em `` `backticks` ``.

⚠️ A skill `dart-flutter:dart-write-documentation` traz **estas mesmas convenções de
forma, porém em inglês**. Aproveite a forma; ignore o idioma dos exemplos dela. A
precedência está em `documentacao.md`: skill é prática, e a prática daqui é esta tabela.

## Acentuação não é opcional

Em qualquer texto em português — documento, commit, resposta, comentário — a acentuação
é completa. *"Nao"*, *"codigo"* e *"orcamento"* são erros ortográficos, não abreviações.

A contrapartida vale igualmente: **identificador de código não leva acento**, e é por
isso que ele é em inglês.

## Toda tabela e todo diagrama levam legenda

Material técnico — tabela, diagrama, classificação, série de identificadores — vai
acompanhado de legenda que o torne legível para quem não é da área. Um diagrama sem
legenda é um desenho que só quem já sabe consegue ler, e um documento que só o autor
entende não documentou nada.
