import 'dart:convert';
import 'dart:io';

import 'hooks.dart';
import 'raiz.dart';

const _motivoDoBloqueio = '''
Todo vermelho na sessao e regressao a corrigir agora, mesmo que nao tenha sido causado
por esta mudanca (.claude/rules/regressao-zero.md). As tres saidas legitimas sao:
consertar a causa, corrigir o portao mal classificado e provar o verde no caminho certo,
ou escalar ao Gabriel com a causa-raiz nomeada.''';

/// Roda `just check` no fim do turno e bloqueia quando o portão fica vermelho.
///
/// Só age com o working tree sujo. Regenera o README antes de medir, sem
/// commitar. Falha aberta: sem `just` ou `git`, avisa e deixa passar.
RespostaDeHook hookPortao(String bruto) {
  final entrada = _mapa(bruto);
  if (entrada['stop_hook_active'] == true) return RespostaDeHook.silencio;

  final Directory raiz;
  try {
    final cwd = entrada['cwd'];
    raiz = acharRaiz(cwd is String && cwd.isNotEmpty ? cwd : null);
  } on StateError {
    return RespostaDeHook.silencio;
  }

  for (final programa in const ['git', 'just']) {
    if (!_existe(programa)) {
      return RespostaDeHook(
        mensagem:
            "portao: '$programa' nao encontrado — "
            'o portao NAO rodou neste turno.',
      );
    }
  }

  final status = _rodar('git', const ['status', '--porcelain'], raiz);
  if (status.exitCode != 0) return RespostaDeHook.silencio;
  if (status.stdout.toString().trim().isEmpty) return RespostaDeHook.silencio;

  final antes = _hashDoReadme(raiz);
  _rodar('just', const ['readme'], raiz);
  final depois = _hashDoReadme(raiz);

  final portao = _rodar('just', const ['check'], raiz);
  final saida = '${portao.stdout}${portao.stderr}';

  if (portao.exitCode == 0) {
    if (antes != depois) {
      return const RespostaDeHook(
        mensagem:
            'README.md foi regenerado por just readme '
            '(fontes de verdade mudaram) — inclua no commit.',
      );
    }
    return RespostaDeHook.silencio;
  }

  return RespostaDeHook(
    bloqueio:
        "O portao 'just check' falhou (exit ${portao.exitCode}). "
        'Saida literal:\n\n$saida\n$_motivoDoBloqueio',
  );
}

Map<String, Object?> _mapa(String bruto) {
  if (bruto.trim().isEmpty) return const {};
  final decodificado = jsonDecode(bruto);
  return decodificado is Map<String, Object?> ? decodificado : const {};
}

bool _existe(String programa) =>
    Process.runSync('command', ['-v', programa], runInShell: true).exitCode ==
    0;

ProcessResult _rodar(String programa, List<String> args, Directory raiz) =>
    Process.runSync(programa, args, workingDirectory: raiz.path);

String _hashDoReadme(Directory raiz) {
  final resultado = _rodar('git', const ['hash-object', 'README.md'], raiz);
  return resultado.exitCode == 0
      ? resultado.stdout.toString().trim()
      : 'ausente';
}
