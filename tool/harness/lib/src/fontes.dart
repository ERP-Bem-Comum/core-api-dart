import 'dart:io';

import 'package:yaml/yaml.dart';

/// Ordem da cascata de documentação; o índice é a prioridade.
const tiposDeFonte = <String>[
  'mcp',
  'llms-txt',
  'cli',
  'raw-source',
  'web-fetch',
  'offline',
];

const minimoDeFontes = 2;

const _redirecionamento = '_FONTES.md';

/// Valida o catálogo `docs/fontes.yaml` e os arquivos de redirecionamento.
///
/// Devolve a lista de problemas encontrados, vazia quando tudo está correto.
List<String> validarFontes(Directory raiz) {
  final erros = <String>[];
  _validarCatalogo(raiz, erros);
  _validarRedirecionamentos(raiz, erros);
  return erros;
}

void _validarCatalogo(Directory raiz, List<String> erros) {
  final arquivo = File('${raiz.path}/docs/fontes.yaml');
  if (!arquivo.existsSync()) {
    erros.add('docs/fontes.yaml não existe');
    return;
  }

  final Object? conteudo;
  try {
    conteudo = loadYaml(arquivo.readAsStringSync());
  } on YamlException catch (erro) {
    erros.add('docs/fontes.yaml não é YAML válido: $erro');
    return;
  }

  if (conteudo is! YamlList || conteudo.isEmpty) {
    erros.add('docs/fontes.yaml deve ser uma lista não vazia de entradas');
    return;
  }

  final vistos = <String>{};
  for (var i = 0; i < conteudo.length; i++) {
    final entrada = conteudo[i];
    var rotulo = 'entrada #${i + 1}';
    if (entrada is! YamlMap) {
      erros.add('$rotulo: deveria ser um mapa');
      continue;
    }

    final nome = entrada['nome'];
    if (nome is! String || nome.trim().isEmpty) {
      erros.add('$rotulo: campo `nome` ausente ou vazio');
      continue;
    }
    rotulo = '`$nome`';

    if (!vistos.add(nome)) erros.add('$rotulo: duplicada no catálogo');

    if (entrada['usada_para'] is! String) {
      erros.add('$rotulo: campo `usada_para` ausente');
    }

    final fontes = entrada['fontes'];
    if (fontes is! YamlList) {
      erros.add('$rotulo: campo `fontes` ausente ou não é lista');
      continue;
    }

    if (fontes.length < minimoDeFontes) {
      erros.add(
        '$rotulo: ${fontes.length} fonte(s); o mínimo é $minimoDeFontes. '
        'Fonte única é ponto de falha sem nada com que confrontar',
      );
    }

    final prioridades = <int>[];
    for (var j = 0; j < fontes.length; j++) {
      final fonte = fontes[j];
      final fRotulo = '$rotulo, fonte #${j + 1}';
      if (fonte is! YamlMap) {
        erros.add('$fRotulo: deveria ser um mapa');
        continue;
      }
      final tipo = fonte['tipo'];
      if (tipo is! String || !tiposDeFonte.contains(tipo)) {
        erros.add(
          '$fRotulo: tipo $tipo inválido. Use um de: ${tiposDeFonte.join(', ')}',
        );
        continue;
      }
      final onde = fonte['onde'];
      if (onde is! String || onde.trim().isEmpty) {
        erros.add('$fRotulo: campo `onde` ausente');
      }
      prioridades.add(tiposDeFonte.indexOf(tipo));
    }

    if (prioridades.isNotEmpty &&
        prioridades.reduce((a, b) => a < b ? a : b) ==
            tiposDeFonte.indexOf('offline')) {
      erros.add(
        '$rotulo: só tem fonte `offline`. Offline é a posição 6 da cascata, '
        'nunca a primeira parada',
      );
    }
  }
}

void _validarRedirecionamentos(Directory raiz, List<String> erros) {
  final docs = Directory('${raiz.path}/docs');
  if (!docs.existsSync()) {
    erros.add('docs/ não existe');
    return;
  }

  final areas = <Directory>[
    docs,
    ...docs.listSync().whereType<Directory>().where(
      (d) => !_nomeDe(d).startsWith('.'),
    ),
  ]..sort((a, b) => a.path.compareTo(b.path));

  for (final area in areas) {
    if (!File('${area.path}/$_redirecionamento').existsSync()) {
      final relativo = area.path.replaceFirst('${raiz.path}/', '');
      erros.add('$relativo/ sem $_redirecionamento');
    }
  }
}

String _nomeDe(FileSystemEntity entidade) => entidade.uri.pathSegments
    .lastWhere((s) => s.isNotEmpty, orElse: () => entidade.path);
