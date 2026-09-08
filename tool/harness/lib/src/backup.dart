import 'dart:io';

const _quantasManter = 10;

/// Copia o log bruto para fora do repositório, mantendo as [_quantasManter]
/// cópias mais recentes.
///
/// O destino é `AI_LOG_BACKUP_DIR` quando definida, senão
/// `~/.local/share/ai-log-backups/core-api-dart`. O log é gitignored: sem
/// backup, seria cópia única.
int salvarLog(Directory raiz) {
  final origem = File('${raiz.path}/.ai-log/raw-prompts.md');
  if (!origem.existsSync()) {
    stdout.writeln('⏭️  log-backup: nada a salvar');
    return 0;
  }

  final ambiente = Platform.environment;
  final base =
      ambiente['AI_LOG_BACKUP_DIR'] ??
      '${ambiente['HOME']}/.local/share/ai-log-backups';
  final destino = Directory('$base/core-api-dart')..createSync(recursive: true);

  final agora = DateTime.now();
  String dois(int n) => n.toString().padLeft(2, '0');
  final carimbo =
      '${agora.year}${dois(agora.month)}${dois(agora.day)}-'
      '${dois(agora.hour)}${dois(agora.minute)}${dois(agora.second)}';

  final copia = File('${destino.path}/raw-prompts-$carimbo.md');
  origem.copySync(copia.path);

  final antigas =
      destino
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('raw-prompts-'))
          .toList()
        ..sort((a, b) => b.path.compareTo(a.path));

  for (final velha in antigas.skip(_quantasManter)) {
    velha.deleteSync();
  }

  final tamanho = (origem.lengthSync() / 1024).toStringAsFixed(1);
  stdout.writeln('✅ log-backup: ${tamanho}K → ${copia.path}');
  return 0;
}
