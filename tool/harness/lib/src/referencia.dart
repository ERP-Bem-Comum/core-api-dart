import 'dart:io';

class _Referencia {
  const _Referencia(this.pasta, this.assunto, this.indice, this.completa);

  final String pasta;
  final String assunto;
  final String indice;
  final String completa;
}

const _referencias = <_Referencia>[
  _Referencia(
    'claude-code',
    'Claude Code',
    'https://code.claude.com/docs/llms.txt',
    'https://code.claude.com/docs/llms-full.txt',
  ),
  _Referencia(
    'claude-api',
    'API Anthropic',
    'https://platform.claude.com/llms.txt',
    'https://platform.claude.com/llms-full.txt',
  ),
];

/// Baixa a documentação de fallback para `docs/offline-reference/`.
///
/// Posição 6 da cascata: só se consulta quando as cinco fontes vivas falharam.
/// Carimba a data no `_FONTES.md`, sem a qual a cópia envelhece em silêncio.
Future<int> baixarReferencias(Directory raiz) async {
  final base = Directory('${raiz.path}/docs/offline-reference');
  final cliente = HttpClient()..connectionTimeout = const Duration(seconds: 30);

  try {
    for (final referencia in _referencias) {
      final pasta = Directory('${base.path}/${referencia.pasta}')
        ..createSync(recursive: true);
      stdout.writeln('→ ${referencia.assunto}…');
      await _baixar(cliente, referencia.indice, '${pasta.path}/_index.txt');
      await _baixar(cliente, referencia.completa, '${pasta.path}/_full.txt');
    }
  } on SocketException catch (erro) {
    stderr.writeln('❌ refs: rede indisponível — $erro');
    return 1;
  } on HttpException catch (erro) {
    stderr.writeln('❌ refs: $erro');
    return 1;
  } finally {
    cliente.close();
  }

  File('${base.path}/_FONTES.md').writeAsStringSync(_indice());
  stdout.writeln('✅ refs: ${base.path}');
  return 0;
}

Future<void> _baixar(HttpClient cliente, String url, String destino) async {
  final pedido = await cliente.getUrl(Uri.parse(url));
  final resposta = await pedido.close();
  if (resposta.statusCode != 200) {
    throw HttpException('HTTP ${resposta.statusCode}', uri: Uri.parse(url));
  }
  final arquivo = File(destino).openWrite();
  await resposta.pipe(arquivo);
}

String _indice() {
  final hoje = DateTime.now();
  String dois(int n) => n.toString().padLeft(2, '0');
  final data = '${hoje.year}-${dois(hoje.month)}-${dois(hoje.day)}';

  final linhas = _referencias
      .map(
        (r) =>
            '| `${r.pasta}/_index.txt` · `_full.txt` | ${r.assunto} | '
            '${r.completa} |',
      )
      .join('\n');

  return '''
# `docs/offline-reference/` — FALLBACK (posição 6 da cascata)

⚠️ **Esta pasta é a última parada, não a primeira.** Antes de ler qualquer coisa
aqui, tente: MCP → `llms.txt` → CLI → fonte crua → `WebFetch`. A regra completa
está em `.claude/rules/documentacao.md`; o catálogo, em `docs/fontes.yaml`.

Baixada por `just refs-claude` em **$data**. Gitignored.

| Arquivo | Assunto | Origem viva (prefira esta) |
|---------|---------|----------------------------|
$linhas

> **Legenda.** `_index.txt` é o sumário (barato de ler inteiro); `_full.txt` é o
> dump completo — **grande**: use `grep` com âncora e contexto, nunca leia inteiro.
''';
}
