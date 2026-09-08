# Convenção de segredos

`[SECRET:NOME]` no prompt do Gabriel significa: **o valor existe no cofre, resolva de
lá em runtime.** Nunca peça o valor, nunca imprima, nunca cole em arquivo.

Exemplo — ele escreve:

> "conecta no Postgres de staging com a `[SECRET:PG_STAGING_URL]`"

O que fazer:

- Referenciar como `$PG_STAGING_URL` no código ou comando, lendo do ambiente.
- Se não estiver carregada, **dizer qual variável falta** e mandar rodar `loadsecrets` —
  nunca sugerir colar o valor no chat. A fonte única é o cofre cifrado `sops`/`age` em
  `$SECRETS_VAULT` (`~/.config/secrets/secrets.yaml`); desde 2026-09-02 não há mais dotenv
  em texto puro. Ver `~/Desktop/Projetos/GUIA-SEGREDOS-SOPS-AGE.md`.
- Se for preciso rodar algo que exponha a chave, **peça que ele mesmo execute** com o
  prefixo `!` no prompt, em vez de você ler o valor.

`[NOLOG]` em qualquer posição do prompt faz o hook não registrar aquele prompt. Usado
quando ele precisa mesmo colar um valor real — por exemplo, para debugar por que um
token específico está sendo rejeitado.

## A rede de segurança, e o que ela não cobre

Se um segredo real escapar, o redator do harness (`tool/harness/lib/src/redator.dart`) o substitui por
`[REDIGIDO]` no log e avisa na UI.

⚠️ **Isso protege o arquivo, não o terminal nem o transcript da sessão.** Se o aviso de
detecção aparecer, o valor já circulou — **recomende rotacionar a chave**.

## No repositório

- Nenhum valor real de credencial é commitado. O `.env.example` leva apenas as chaves,
  com valores fictícios.
- `permissions.deny` no `settings.json` bloqueia leitura de `.env`, `.env.*` e
  `~/.config/sops/age/**` (a chave que decifra o cofre) pelas ferramentas de arquivo.
  O cofre em si é cifrado — o que precisa de proteção é a chave age.
- **Esse bloqueio não alcança subprocesso.** Um script Dart ou Python que abre o
  arquivo sozinho passa por fora — a proteção é contra leitura acidental do agente,
  não uma garantia de sistema operacional.
