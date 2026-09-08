import 'dart:convert';
import 'dart:io';

const _reset = '[0m';

/// Monta a linha de status: modelo, uso de contexto, custo e estado do git.
///
/// O uso de contexto vem primeiro por ser o recurso mais escasso da sessão.
/// Devolve string vazia quando não há nada a mostrar.
String montarStatusline(String bruto) {
  final Map<String, Object?> entrada;
  try {
    final decodificado = jsonDecode(bruto);
    if (decodificado is! Map<String, Object?>) return '';
    entrada = decodificado;
  } on FormatException {
    return '';
  }

  final partes = <String>[];

  final modelo = _texto(entrada, ['model', 'display_name']);
  if (modelo != null) partes.add('[1;35m$modelo$_reset');

  final usados = _inteiro(entrada, ['context', 'used_tokens']);
  final total = _inteiro(entrada, ['context', 'total_tokens']);
  if (usados != null && total != null && total > 0) {
    final porcento = usados * 100 ~/ total;
    final cor = porcento < 50 ? '32' : (porcento < 80 ? '33' : '31');
    partes.add('[0;${cor}m$porcento% ctx$_reset');
  }

  final custo = _numero(entrada, ['cost', 'total_cost_usd']);
  if (custo != null) {
    partes.add('[0;36m\$${custo.toStringAsFixed(2)}$_reset');
  }

  final dir = _texto(entrada, ['workspace', 'current_dir']);
  if (dir != null) {
    final git = _git(dir);
    if (git != null) partes.add(git);
  }

  return partes.join(' │ ');
}

String? _git(String dir) {
  if (_rodar(dir, const ['rev-parse', '--git-dir']) == null) return null;

  final branch =
      _rodar(dir, const ['branch', '--show-current']) ??
      _rodar(dir, const ['rev-parse', '--short', 'HEAD']) ??
      '?';
  final status = _rodar(dir, const ['status', '--porcelain']) ?? '';
  final sujos = status.isEmpty ? 0 : status.split('\n').length;

  return sujos > 0
      ? '[0;33m⎇ $branch*$sujos$_reset'
      : '[0;32m⎇ $branch$_reset';
}

String? _rodar(String dir, List<String> argumentos) {
  final resultado = Process.runSync('git', argumentos, workingDirectory: dir);
  if (resultado.exitCode != 0) return null;
  final saida = resultado.stdout.toString().trim();
  return saida.isEmpty ? null : saida;
}

Object? _navegar(Map<String, Object?> mapa, List<String> caminho) {
  Object? atual = mapa;
  for (final chave in caminho) {
    if (atual is! Map<String, Object?>) return null;
    atual = atual[chave];
  }
  return atual;
}

String? _texto(Map<String, Object?> mapa, List<String> caminho) {
  final valor = _navegar(mapa, caminho);
  return valor is String && valor.isNotEmpty ? valor : null;
}

int? _inteiro(Map<String, Object?> mapa, List<String> caminho) {
  final valor = _navegar(mapa, caminho);
  return valor is int ? valor : null;
}

double? _numero(Map<String, Object?> mapa, List<String> caminho) {
  final valor = _navegar(mapa, caminho);
  return valor is num ? valor.toDouble() : null;
}
