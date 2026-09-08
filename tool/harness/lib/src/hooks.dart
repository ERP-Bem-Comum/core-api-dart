import 'dart:convert';
import 'dart:io';

import 'raiz.dart';
import 'redator.dart';

const _marcador = '<!-- ai-log:entry -->';

/// Decisão que um hook devolve ao Claude Code pelo stdout.
class RespostaDeHook {
  const RespostaDeHook({this.mensagem, this.bloqueio});

  /// Aviso exibido na interface, sem entrar no contexto do modelo.
  final String? mensagem;

  /// Motivo do bloqueio; quando presente, o turno não encerra.
  final String? bloqueio;

  static const silencio = RespostaDeHook();

  String? get json {
    if (bloqueio != null) {
      return jsonEncode({'decision': 'block', 'reason': bloqueio});
    }
    if (mensagem != null) return jsonEncode({'systemMessage': mensagem});
    return null;
  }
}

Map<String, Object?> _entrada(String bruto) {
  if (bruto.trim().isEmpty) return const {};
  final decodificado = jsonDecode(bruto);
  return decodificado is Map<String, Object?> ? decodificado : const {};
}

String? _texto(Map<String, Object?> mapa, String chave) {
  final valor = mapa[chave];
  return valor is String && valor.isNotEmpty ? valor : null;
}

File _arquivoDeLog(Map<String, Object?> entrada) {
  final raiz = _raizDe(entrada);
  final pasta = Directory('${raiz.path}/.ai-log')..createSync(recursive: true);
  return File('${pasta.path}/raw-prompts.md');
}

Directory _raizDe(Map<String, Object?> entrada) {
  final cwd = _texto(entrada, 'cwd');
  try {
    return acharRaiz(cwd);
  } on StateError {
    return Directory(cwd ?? Directory.current.path);
  }
}

String _cabecalho(Map<String, Object?> entrada) {
  final agora = DateTime.now();
  String dois(int n) => n.toString().padLeft(2, '0');
  final carimbo =
      '${agora.year}-${dois(agora.month)}-${dois(agora.day)} '
      '${dois(agora.hour)}:${dois(agora.minute)}';
  final sessao = _texto(entrada, 'session_id') ?? '????????';
  final curta = sessao.length >= 8 ? sessao.substring(0, 8) : sessao;
  return '\n---\n\n$_marcador\n### $carimbo · sessão `$curta`\n\n';
}

/// Registra o prompt do usuário em `.ai-log/raw-prompts.md`.
///
/// Omite o conteúdo quando o prompt traz `[NOLOG]` e redige credenciais que
/// escaparem. Devolve a resposta a escrever no stdout do hook.
RespostaDeHook hookPrompt(String bruto) {
  final entrada = _entrada(bruto);
  final prompt = _texto(entrada, 'prompt');
  if (prompt == null) return RespostaDeHook.silencio;

  final log = _arquivoDeLog(entrada);
  final cabecalho = _cabecalho(entrada);

  if (prompt.contains('[NOLOG]')) {
    log.writeAsStringSync(
      '$cabecalho${'_(prompt omitido do log — marcado com [NOLOG])_'}\n',
      mode: FileMode.append,
    );
    return RespostaDeHook.silencio;
  }

  final seguro = redigir(prompt);
  final aviso = seguro.houveDeteccao
      ? '> ⚠️ Credencial real detectada e redigida automaticamente.\n\n'
      : '';

  log.writeAsStringSync(
    '$cabecalho$aviso~~~\n${seguro.texto}\n~~~\n',
    mode: FileMode.append,
  );

  if (!seguro.houveDeteccao) return RespostaDeHook.silencio;
  return const RespostaDeHook(
    mensagem:
        'Credencial real detectada no prompt e redigida do .ai-log. '
        'Ela ainda passou pelo terminal e pelo transcript — considere '
        'rotacionar. Use [SECRET:NOME] para referenciar segredos sem colar '
        'o valor.',
  );
}

/// Registra a resposta dada a um `AskUserQuestion`.
///
/// Ignora qualquer outra ferramenta. As observações escritas à mão costumam ser
/// as intervenções mais decisivas de uma sessão.
RespostaDeHook hookResposta(String bruto) {
  final entrada = _entrada(bruto);
  if (_texto(entrada, 'tool_name') != 'AskUserQuestion') {
    return RespostaDeHook.silencio;
  }

  final resposta = entrada['tool_response'];
  final pedido = entrada['tool_input'];
  if (resposta == null) return RespostaDeHook.silencio;

  final perguntas = <String>[];
  if (pedido is Map<String, Object?>) {
    final lista = pedido['questions'];
    if (lista is List) {
      for (final item in lista) {
        if (item is Map<String, Object?>) {
          final texto = _texto(item, 'question');
          if (texto != null) perguntas.add(texto);
        }
      }
    }
  }

  final seguro = redigir(_serializar(resposta));
  final buffer = StringBuffer(_cabecalho(entrada))
    ..writeln('<!-- ai-log:answer -->')
    ..writeln('**Resposta ao AskUserQuestion**');
  for (final pergunta in perguntas) {
    buffer.writeln('- _${pergunta.replaceAll('\n', ' ')}_');
  }
  buffer.write('\n~~~\n${seguro.texto}\n~~~\n');

  _arquivoDeLog(entrada)
      .writeAsStringSync(buffer.toString(), mode: FileMode.append);
  return RespostaDeHook.silencio;
}

String _serializar(Object? valor) {
  if (valor is String) return valor;
  return const JsonEncoder.withIndent('  ').convert(valor);
}
