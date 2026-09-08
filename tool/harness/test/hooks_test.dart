import 'dart:convert';
import 'dart:io';

import 'package:harness/src/hooks.dart';
import 'package:test/test.dart';

void main() {
  late Directory temporaria;

  setUp(() {
    temporaria = Directory.systemTemp.createTempSync('harness-hooks');
    File('${temporaria.path}/Justfile').writeAsStringSync('default:\n');
  });

  tearDown(() => temporaria.deleteSync(recursive: true));

  String log() =>
      File('${temporaria.path}/.ai-log/raw-prompts.md').readAsStringSync();

  String entrada(Map<String, Object?> campos) =>
      jsonEncode({'cwd': temporaria.path, 'session_id': 'abcd1234', ...campos});

  group('hookPrompt', () {
    test('grava o prompt e não fala nada', () {
      final resposta = hookPrompt(entrada({'prompt': 'roda o just check'}));
      expect(resposta.json, isNull);
      expect(log(), contains('roda o just check'));
      expect(log(), contains('<!-- ai-log:entry -->'));
    });

    test('[NOLOG] omite o conteúdo mas deixa rastro', () {
      hookPrompt(entrada({'prompt': 'segredo aqui [NOLOG]'}));
      expect(log(), isNot(contains('segredo aqui')));
      expect(log(), contains('[NOLOG]'));
      expect(log(), contains('<!-- ai-log:entry -->'));
    });

    test('credencial não é gravada e a UI é avisada', () {
      final resposta = hookPrompt(
        entrada({'prompt': 'usa AKIAIOSFODNN7EXAMPLE'}),
      );
      expect(log(), isNot(contains('AKIAIOSFODNN7EXAMPLE')));
      expect(log(), contains('[REDIGIDO'));

      final json = resposta.json;
      expect(json, isNotNull);
      final decodificado = jsonDecode(json!) as Map<String, Object?>;
      expect(decodificado['systemMessage'], contains('rotacionar'));
    });

    test('payload sem prompt não cria arquivo', () {
      final resposta = hookPrompt(entrada({}));
      expect(resposta.json, isNull);
      expect(
        File('${temporaria.path}/.ai-log/raw-prompts.md').existsSync(),
        isFalse,
      );
    });
  });

  group('hookResposta', () {
    test('ignora ferramenta que não é AskUserQuestion', () {
      final resposta = hookResposta(
        entrada({'tool_name': 'Bash', 'tool_response': 'ok'}),
      );
      expect(resposta.json, isNull);
      expect(
        File('${temporaria.path}/.ai-log/raw-prompts.md').existsSync(),
        isFalse,
      );
    });

    test('registra a resposta junto da pergunta', () {
      hookResposta(
        entrada({
          'tool_name': 'AskUserQuestion',
          'tool_input': {
            'questions': [
              {'question': 'Mantemos o just?'},
            ],
          },
          'tool_response': 'Manter',
        }),
      );
      expect(log(), contains('Mantemos o just?'));
      expect(log(), contains('Manter'));
      expect(log(), contains('<!-- ai-log:answer -->'));
    });
  });

  group('RespostaDeHook', () {
    test('bloqueio vira decision:block com o motivo', () {
      const resposta = RespostaDeHook(bloqueio: 'portão vermelho');
      final json = jsonDecode(resposta.json!) as Map<String, Object?>;
      expect(json['decision'], 'block');
      expect(json['reason'], 'portão vermelho');
    });

    test('silêncio não produz JSON', () {
      expect(RespostaDeHook.silencio.json, isNull);
    });
  });
}
