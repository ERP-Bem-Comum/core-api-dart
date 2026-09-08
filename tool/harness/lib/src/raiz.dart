import 'dart:io';

/// Raiz do repositório, descoberta subindo até achar o `Justfile`.
///
/// Quando [partida] é informada, a busca começa dali e o ambiente é ignorado —
/// um caminho explícito sempre ganha de `CLAUDE_PROJECT_DIR`, que só serve de
/// padrão para quem não sabe onde está. Lança [StateError] se nada for achado.
Directory acharRaiz([String? partida]) {
  final inicio = partida != null && partida.isNotEmpty
      ? partida
      : _doAmbiente() ?? Directory.current.path;

  var atual = Directory(inicio).absolute;
  while (true) {
    if (File('${atual.path}/Justfile').existsSync()) return atual;
    final pai = atual.parent;
    if (pai.path == atual.path) {
      throw StateError(
        'raiz do repositório não encontrada a partir de $inicio',
      );
    }
    atual = pai;
  }
}

String? _doAmbiente() {
  final valor = Platform.environment['CLAUDE_PROJECT_DIR'];
  if (valor == null || valor.isEmpty) return null;
  return Directory(valor).existsSync() ? valor : null;
}
