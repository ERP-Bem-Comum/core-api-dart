import 'dart:io';

/// Teto de linhas de comentário tolerado num arquivo de configuração.
const tetoDeComentarioEmConfig = 15;

const _extensoesDeConfig = <String>{
  '.yaml',
  '.yml',
  '.json',
  '.toml',
  '.gitignore',
};

const _pastasIgnoradas = <String>{
  '.git',
  '.dart_tool',
  'build',
  'wiki',
  'docs',
  '.ai-log',
  '.agents',
};

/// Verifica a regra de comentários (`.claude/rules/comentarios.md`).
///
/// Em `.dart`, reprova qualquer `//` que não seja dartdoc `///`. Em arquivos de
/// configuração, reprova densidade de comentário acima de
/// [tetoDeComentarioEmConfig] por cento. Devolve a lista de problemas.
List<String> validarComentarios(Directory raiz) {
  final erros = <String>[];

  for (final arquivo in _arquivos(raiz)) {
    final ehDart = arquivo.path.endsWith('.dart');
    if (!ehDart && !_ehConfig(arquivo.path)) continue;

    final relativo = arquivo.path.replaceFirst('${raiz.path}/', '');
    final List<String> linhas;
    try {
      linhas = arquivo.readAsLinesSync();
    } on FileSystemException {
      continue;
    }

    if (ehDart) {
      erros.addAll(_dart(relativo, linhas));
      continue;
    }
    final erro = _config(relativo, linhas);
    if (erro != null) erros.add(erro);
  }

  return erros;
}

Iterable<File> _arquivos(Directory raiz) sync* {
  for (final entidade in raiz.listSync(recursive: false)) {
    if (entidade is Directory) {
      final nome = entidade.path.split('/').last;
      if (_pastasIgnoradas.contains(nome)) continue;
      yield* _arquivos(entidade);
    } else if (entidade is File) {
      yield entidade;
    }
  }
}

bool _ehConfig(String caminho) {
  final nome = caminho.split('/').last;
  if (nome == 'Justfile' || nome == '.gitignore') return true;
  return _extensoesDeConfig.any(nome.endsWith);
}

List<String> _dart(String arquivo, List<String> linhas) {
  final erros = <String>[];
  var dentroDeBloco = false;

  for (var i = 0; i < linhas.length; i++) {
    final linha = linhas[i].trim();

    if (dentroDeBloco) {
      if (linha.contains('*/')) dentroDeBloco = false;
      continue;
    }
    if (linha.startsWith('/*')) {
      dentroDeBloco = !linha.contains('*/');
      erros.add(
        '$arquivo:${i + 1}: comentário de bloco — use `///` sobre a '
        'declaração',
      );
      continue;
    }
    if (linha.startsWith('///') || linha.startsWith('#!')) continue;
    if (linha.startsWith('//')) {
      erros.add(
        '$arquivo:${i + 1}: `//` proibido em Dart — só `///` ancorado a '
        'uma declaração (.claude/rules/comentarios.md)',
      );
    }
  }

  return erros;
}

final _receita = RegExp(r'^[a-z][a-z0-9-]*(\s*:|:)');

bool _documentaReceita(List<String> linhas, int i) {
  for (var j = i + 1; j < linhas.length; j++) {
    final proxima = linhas[j];
    if (proxima.trim().isEmpty) return false;
    if (proxima.trimLeft().startsWith('#')) continue;
    return _receita.hasMatch(proxima);
  }
  return false;
}

String? _config(String arquivo, List<String> linhas) {
  final uteis = linhas.where((l) => l.trim().isNotEmpty).length;
  if (uteis == 0) return null;

  var comentadas = 0;
  for (var i = 0; i < linhas.length; i++) {
    final linha = linhas[i].trimLeft();
    if (!linha.startsWith('#') || linha.startsWith('#!')) continue;
    if (_documentaReceita(linhas, i)) continue;
    comentadas++;
  }
  final porcento = comentadas * 100 ~/ uteis;
  if (porcento <= tetoDeComentarioEmConfig) return null;

  return '$arquivo: $porcento% de comentário '
      '($comentadas de $uteis linhas), acima do teto de '
      '$tetoDeComentarioEmConfig%. Configuração diz o quê, nunca o porquê '
      '(.claude/rules/comentarios.md)';
}
