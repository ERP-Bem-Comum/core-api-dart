# Verificação — os três rótulos

Toda afirmação técnica neste repositório vem rotulada. Quem lê precisa saber quanto
confiar, e a diferença entre "eu rodei" e "eu acho" é a diferença entre um achado e
um palpite.

| Rótulo | Significa | O que precisa acompanhar |
|--------|-----------|--------------------------|
| **Verificado** | Você rodou o comando e viu a saída, ou leu o arquivo | O comando e a **saída literal**, ou `arquivo:linha` |
| **Documentado** | A fonte canônica afirma, e você não testou | A fonte, com URL, página ou linha — e a **versão** |
| **Inferido** | Sua leitura do conjunto | Nada. Mas diga que é inferência |

> **Legenda.** "Fonte canônica" é a documentação oficial da ferramenta, a norma, ou o
> livro — não a memória do modelo, que tem prazo de validade.

## Relatório cola a saída, nunca a conclusão

Escrever *"os testes passaram"* sem a saída é o modo de falha mais comum e o mais
difícil de detectar depois. **Se você não rodou, não reporte.** Se rodou e falhou,
reporte o vermelho.

Quando um teste falha por erro seu — sintaxe, payload malformado, caminho errado —
diga que foi erro do teste. Não deixe passar como resultado do sistema.

## Versão sempre

Comportamento de ferramenta muda entre versões. Um achado sem versão envelhece em
silêncio e volta a ser citado meses depois, já falso.

**Versões entram como número explícito, nunca como "a mais recente".**

## Herdar achado alheio não dispensa verificar

Repassar a conclusão de outro agente ou de outro documento sem abrir a fonte é herdar
o recorte de outra pessoa. Se você vai afirmar, você é responsável pelo rótulo.

## O teste que pega o erro caro

Antes de publicar uma conclusão apoiada numa citação ou numa saída de comando:
**existe alguma leitura da fonte em que ela diz o contrário do que estou concluindo?**

Se você não leu o suficiente para responder, não leu o suficiente para citar.
