/// Resultado de uma passagem do redator sobre um texto.
class TextoRedigido {
  const TextoRedigido(this.texto, {required this.houveDeteccao});

  /// O texto com cada credencial substituída por `[REDIGIDO: ...]`.
  final String texto;

  /// Se alguma credencial foi encontrada e substituída.
  final bool houveDeteccao;
}

class _Regra {
  const _Regra(this.expressao, this.substituicao);

  final RegExp expressao;
  final String substituicao;
}

const _placeholders =
    r'\$|\[|<|\{\{|%\(|\#\{|x{3,}|X{3,}|\.\.\.|your[_-]|seu[_-]|my[_-]'
    r'|changeme|placeholder|example|dummy|test'
    r'|process\.env|os\.environ|System\.getenv|Deno\.env'
    r'|import\.meta|ENV\[|ENV\.|getenv|config\.|this\.|self\.'
    r'''|["']?\s*$''';

const _nomesDeSegredo =
    r'\w*(?:API[_-]?KEY|APIKEY|TOKEN|SECRET|PASSWORD|PASSWD|SENHA'
    r'|ACCESS[_-]?KEY|PRIVATE[_-]?KEY|CLIENT[_-]?SECRET|AUTH[_-]?TOKEN'
    r'|BWS[_-]?ACCESS[_-]?TOKEN)\w*';

final _regras = <_Regra>[
  _Regra(
    RegExp(
      r'-----BEGIN[^\n-]*PRIVATE KEY[^\n-]*-----[\s\S]*?'
      r'-----END[^\n-]*PRIVATE KEY[^\n-]*-----',
    ),
    '[REDIGIDO: chave privada]',
  ),
  _Regra(
    RegExp(
      r'-----BEGIN PGP PRIVATE KEY BLOCK-----[\s\S]*?'
      r'-----END PGP PRIVATE KEY BLOCK-----',
    ),
    '[REDIGIDO: chave PGP]',
  ),
  _Regra(
    RegExp(r'\bsk-ant-[A-Za-z0-9_\-]{20,}'),
    '[REDIGIDO: token Anthropic]',
  ),
  _Regra(RegExp(r'\bsk-proj-[A-Za-z0-9_\-]{20,}'), '[REDIGIDO: token OpenAI]'),
  _Regra(RegExp(r'\bsk-[A-Za-z0-9]{32,}'), '[REDIGIDO: token]'),
  _Regra(RegExp(r'\bgithub_pat_[A-Za-z0-9_]{20,}'), '[REDIGIDO: PAT GitHub]'),
  _Regra(RegExp(r'\bgh[pousr]_[A-Za-z0-9]{30,}'), '[REDIGIDO: token GitHub]'),
  _Regra(RegExp(r'\bglpat-[A-Za-z0-9_\-]{15,}'), '[REDIGIDO: token GitLab]'),
  _Regra(RegExp(r'\bAKIA[0-9A-Z]{16}\b'), '[REDIGIDO: AWS access key id]'),
  _Regra(RegExp(r'\bASIA[0-9A-Z]{16}\b'), '[REDIGIDO: AWS session key id]'),
  _Regra(RegExp(r'\bAIza[A-Za-z0-9_\-]{30,}'), '[REDIGIDO: chave Google]'),
  _Regra(
    RegExp(r'\bxox[baprse]-[A-Za-z0-9\-]{10,}'),
    '[REDIGIDO: token Slack]',
  ),
  _Regra(
    RegExp(r'\btskey-[a-z]+-[A-Za-z0-9\-]{10,}'),
    '[REDIGIDO: chave Tailscale]',
  ),
  _Regra(RegExp(r'\bAC[a-f0-9]{32}\b'), '[REDIGIDO: Twilio SID]'),
  _Regra(RegExp(r'\bdop_v1_[a-f0-9]{60,}'), '[REDIGIDO: token DigitalOcean]'),
  _Regra(RegExp(r'\bAGE-SECRET-KEY-1[0-9A-Z]{50,}'), '[REDIGIDO: chave age]'),
  _Regra(
    RegExp(r'\beyJ[A-Za-z0-9_\-]{8,}\.[A-Za-z0-9_\-]{8,}\.[A-Za-z0-9_\-]{8,}'),
    '[REDIGIDO: JWT]',
  ),
];

final _credencialEmUrl = RegExp(r'(\w+://[^\s:/@]+):([^\s@/]{4,})@');

final _headerDeAutorizacao = RegExp(
  r'\b(Authorization\s*:\s*(?:Bearer|Basic|Token)\s+)[A-Za-z0-9_\-.=+/]{16,}',
  caseSensitive: false,
);

final _atribuicao = RegExp(
  r'(?<!\[)\b(' +
      _nomesDeSegredo +
      r')(\s*[:=]\s*)' +
      r'''(["']?)''' +
      '(?!$_placeholders)' +
      r'(?![A-Za-z_\$][\w\$]*(?:\.[\w\$]+)+[\s;,\)\]\}]*(?:\n|$))' +
      r'''([^\s"'\n]{12,})\3''',
  caseSensitive: false,
  multiLine: true,
);

/// Substitui credenciais reais por `[REDIGIDO: ...]`.
///
/// Placeholders, templates e referências a variável de ambiente passam intactos,
/// assim como a convenção `[SECRET:NOME]`, que não carrega valor algum.
///
/// ```dart
/// redigir('AWS=AKIAIOSFODNN7EXAMPLE').houveDeteccao; // true
/// redigir('API_KEY=\$MINHA_VAR').houveDeteccao; // false
/// ```
TextoRedigido redigir(String entrada) {
  var texto = entrada;

  for (final regra in _regras) {
    texto = texto.replaceAll(regra.expressao, regra.substituicao);
  }

  texto = texto.replaceAllMapped(
    _credencialEmUrl,
    (m) => '${m[1]}:[REDIGIDO]@',
  );
  texto = texto.replaceAllMapped(
    _headerDeAutorizacao,
    (m) => '${m[1]}[REDIGIDO]',
  );
  texto = texto.replaceAllMapped(
    _atribuicao,
    (m) => '${m[1]}${m[2]}${m[3]}[REDIGIDO]${m[3]}',
  );

  return TextoRedigido(texto, houveDeteccao: texto != entrada);
}
