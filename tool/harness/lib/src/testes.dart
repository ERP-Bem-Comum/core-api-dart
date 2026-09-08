import 'dart:io';

import 'package:yaml/yaml.dart';

/// Roda `dart test` sobre todo membro do workspace que tenha suíte.
///
/// Devolve o código de saída do `dart test`, ou 0 quando ainda não há suíte
/// alguma — um repositório sem testes não é uma falha, mas o silêncio é dito.
Future<int> rodarTestes(Directory raiz) async {
  final alvos = <String>[];

  for (final membro in membrosDoWorkspace(raiz)) {
    if (Directory('${raiz.path}/$membro/test').existsSync()) alvos.add(membro);
  }
  if (Directory('${raiz.path}/test').existsSync()) alvos.add('test');

  if (alvos.isEmpty) {
    stdout.writeln('⏭️  test: nenhuma suíte ainda');
    return 0;
  }

  final processo = await Process.start(
    'dart',
    ['test', ...alvos],
    workingDirectory: raiz.path,
    mode: ProcessStartMode.inheritStdio,
    environment: {'CLAUDE_PROJECT_DIR': raiz.path},
  );
  return processo.exitCode;
}

/// Caminhos relativos dos membros declarados em `workspace:`.
List<String> membrosDoWorkspace(Directory raiz) {
  final pubspec = File('${raiz.path}/pubspec.yaml');
  if (!pubspec.existsSync()) return const [];

  final conteudo = loadYaml(pubspec.readAsStringSync());
  if (conteudo is! YamlMap) return const [];

  final membros = conteudo['workspace'];
  if (membros is! YamlList) return const [];

  return [
    for (final membro in membros)
      if (membro is String) membro,
  ];
}
