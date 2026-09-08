# Dart de sabor Swift

Este projeto escreve Dart como quem escreve Swift moderno: **estados impossíveis não
devem compilar**, dado é imutável por padrão, e erro esperado é valor de retorno — não
exceção.

Não é Dart "orientado a objetos clássico" (herança profunda, setters, mutação in
place) nem Dart "funcional puro" com biblioteca de efeitos. **`fp-dart` está fora.**

## O que usar

| Recurso | Para quê |
|---------|----------|
| `sealed class` + `switch` exaustivo | Modelar o conjunto **fechado** de estados de um agregado. O compilador recusa o caso não tratado |
| `extension type` | Identidade e unidade sem custo de alocação — `PartnerId`, `Cents`, `Cnpj`. String crua atravessando camada é defeito |
| `final class` / campos `final` | Padrão. Mutabilidade é exceção que se justifica |
| `Result` / união de sucesso e falha | Erro **esperado** é valor. `throw` fica para o que não deveria acontecer |
| `Isolate` | Paralelismo real de CPU. Não use para orquestrar I/O — `Future` já resolve |
| `record` | Retorno múltiplo local, sem inventar classe de uma linha |

## O que evitar

- **Herança para reuso.** Composição, `mixin` com contrato claro, ou função livre.
- **`dynamic`.** Se o tipo é desconhecido, a fronteira é que está errada.
- **Exceção como fluxo de controle.** `PartnerNotFound` é um caso do domínio, não um
  `throw` que alguém talvez pegue.
- **Getter que faz I/O.** Propriedade não vai ao banco.
- **`late` para adiar decisão de desenho.** `late` é promessa que o compilador não
  cobra; quase sempre denuncia construção mal modelada.

## Onde o tipo mora

Hexagonal, e a direção da dependência é a regra que não se quebra: **o domínio não
importa infraestrutura.** Um tipo do domínio não conhece Postgres, HTTP nem JSON.

- Domínio expõe **portas** (interfaces).
- Infraestrutura implementa **adaptadores**.
- Serialização é problema do adaptador — `toJson` não pertence à entidade.

## Erro esperado tem nome fechado

O conjunto de falhas de uma operação é enumerável e faz parte da assinatura. Uma união
de literais em `kebab-case` — `'partner-not-found'`, `'budget-exceeded'` — é o que vira
`switch` no chamador. Distinta da frase mostrada a uma pessoa, que é PT-BR e vive na
camada de apresentação (ver `idioma.md`).

## Testes: mocks gerados, não fakes à mão

Dependência externa em teste é substituída por **mock gerado com `mockito` +
`build_runner`** — `@GenerateNiceMocks`, `dart run build_runner build`. Não escrevemos
classes fake à mão implementando as portas.

O motivo é peso: o mock do Dart é leve e o gerador cobre o caso comum sem cerimônia,
enquanto um fake manual é código de produção que ninguém testa e que silenciosamente
deixa de acompanhar a porta quando ela muda.

A skill `dart-flutter:dart-generate-test-mocks` é o procedimento canônico disto — e o
que ela prega sobre desenho **coincide** com o nosso: injetar dependência externa pelo
construtor, e interface clara para cada interação externa. Isso é a porta hexagonal.

> O que **não** se mocka: tipo do próprio domínio. `Money`, `Cnpj`, um agregado — são
> valores, constrói-se o de verdade. Mock é para o que está do outro lado de uma porta.

## Antes de decidir estilo novo

Este arquivo descreve o que já está decidido. Se aparecer um caso que ele não cobre,
**pergunte antes de estabelecer o padrão sozinho** — convenção nasce uma vez e depois
custa caro para mudar.
