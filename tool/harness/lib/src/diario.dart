import 'dart:io';

/// Página do diário pronta para publicar na wiki.
class PaginaDeDiario {
  const PaginaDeDiario({required this.nome, required this.corpo, this.wiki});

  final String nome;
  final String corpo;

  /// URL do repositório de wiki, ou `null` quando não há `origin`.
  final String? wiki;
}

/// Monta a página do diário com os commits e a contagem de prompts do período.
PaginaDeDiario montarPagina(Directory raiz) {
  final origem = _git(raiz, const ['remote', 'get-url', 'origin']);
  final wiki = origem == null
      ? null
      : origem.endsWith('.git')
      ? '${origem.substring(0, origem.length - 4)}.wiki.git'
      : '$origem.wiki.git';

  final branch =
      _git(raiz, const ['symbolic-ref', '--short', 'HEAD']) ?? 'desconhecida';

  final marca = File('${raiz.path}/.ai-log/.ultima-publicacao');
  final desde = marca.existsSync() ? marca.readAsStringSync().trim() : '';
  final valido =
      desde.isNotEmpty && _git(raiz, ['cat-file', '-t', desde]) == 'commit';
  final intervalo = valido ? '$desde..HEAD' : 'HEAD';

  final log = _git(raiz, [
    'log',
    '--no-merges',
    '--pretty=- `%h` %s',
    intervalo,
  ]);
  final commits = (log == null || log.isEmpty)
      ? '_nenhum commit novo._'
      : log.split('\n').take(50).join('\n');
  final quantos = commits.startsWith('- ')
      ? commits.split('\n').where((l) => l.startsWith('- ')).length
      : 0;

  final bruto = File('${raiz.path}/.ai-log/raw-prompts.md');
  var prompts = 0;
  var linhas = 0;
  if (bruto.existsSync()) {
    final conteudo = bruto.readAsLinesSync();
    linhas = conteudo.length;
    prompts = conteudo.where((l) => l.trim() == '<!-- ai-log:entry -->').length;
  }

  final agora = DateTime.now();
  String dois(int n) => n.toString().padLeft(2, '0');
  final carimbo =
      '${agora.year}-${dois(agora.month)}-${dois(agora.day)}-'
      '${dois(agora.hour)}${dois(agora.minute)}${dois(agora.second)}';

  final corpo =
      '''
# Diário — $carimbo

| Campo | Valor |
|-------|-------|
| Branch | `$branch` |
| Commits publicados | $quantos |
| Prompts na captura bruta | $prompts ($linhas linhas) |

> **Legenda.** A *captura bruta* fica apenas na máquina de quem trabalhou
> (`.ai-log/`, gitignored). Esta página é o recorte publicado.

## Commits

$commits

## Como a IA foi usada

_Preencha: o que travou, o que a IA acertou, onde ela errou e como o erro apareceu._
''';

  return PaginaDeDiario(nome: 'Diario-$carimbo.md', corpo: corpo, wiki: wiki);
}

/// Publica a página na wiki do versionador.
///
/// Devolve a mensagem a exibir. Nunca lança: um diário que falha não pode
/// impedir um push.
String publicar(Directory raiz, PaginaDeDiario pagina) {
  final wiki = pagina.wiki;
  if (wiki == null) return "diario: sem 'origin' configurado — nada publicado.";

  final cache = Directory(
    '${Platform.environment['HOME']}/.cache/core-api-dart-wiki',
  );

  if (Directory('${cache.path}/.git').existsSync()) {
    Process.runSync('git', const [
      'pull',
      '--quiet',
      '--ff-only',
    ], workingDirectory: cache.path);
  } else {
    if (cache.existsSync()) cache.deleteSync(recursive: true);
    final clone = Process.runSync('git', [
      'clone',
      '--quiet',
      wiki,
      cache.path,
    ]);
    if (clone.exitCode != 0) {
      return "diario: wiki '$wiki' inacessível — crie a primeira página pela "
          'interface web.';
    }
  }

  File('${cache.path}/${pagina.nome}').writeAsStringSync(pagina.corpo);
  Process.runSync('git', ['add', pagina.nome], workingDirectory: cache.path);
  Process.runSync('git', [
    'commit',
    '--quiet',
    '-m',
    'diário: ${pagina.nome}',
  ], workingDirectory: cache.path);
  final push = Process.runSync('git', const [
    'push',
    '--quiet',
  ], workingDirectory: cache.path);
  if (push.exitCode != 0) {
    return 'diario: push falhou — página em ${cache.path}/${pagina.nome}';
  }

  final head = _git(raiz, const ['rev-parse', 'HEAD']);
  if (head != null) {
    File('${raiz.path}/.ai-log/.ultima-publicacao').writeAsStringSync(head);
  }
  return 'diario: ${pagina.nome} publicado.';
}

String? _git(Directory raiz, List<String> argumentos) {
  final resultado = Process.runSync(
    'git',
    argumentos,
    workingDirectory: raiz.path,
  );
  if (resultado.exitCode != 0) return null;
  final saida = resultado.stdout.toString().trim();
  return saida.isEmpty ? null : saida;
}
