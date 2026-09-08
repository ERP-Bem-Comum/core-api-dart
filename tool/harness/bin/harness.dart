import 'dart:convert';
import 'dart:io';

import 'package:harness/src/backup.dart';
import 'package:harness/src/comentarios.dart';
import 'package:harness/src/diario.dart';
import 'package:harness/src/fontes.dart';
import 'package:harness/src/hooks.dart';
import 'package:harness/src/portao.dart';
import 'package:harness/src/raiz.dart';
import 'package:harness/src/readme.dart';
import 'package:harness/src/referencia.dart';
import 'package:harness/src/statusline.dart';
import 'package:harness/src/testes.dart';

const _uso = '''
harness — ferramentas do repositório core-api-dart

  fontes                 valida o catálogo de documentação
  comentarios            valida a regra de comentários
  readme [--check]       regenera o README, ou reprova se estiver desatualizado
  diario [--dry-run]     publica a página do diário na wiki
  log-backup             salva o log bruto fora do repositório
  refs-claude            baixa a doc de fallback (posição 6 da cascata)
  hook-prompt            hook UserPromptSubmit (lê JSON no stdin)
  hook-answer            hook PostToolUse/AskUserQuestion
  hook-stop              hook Stop, roda o portão
  statusline             linha de status da sessão
  test                   roda dart test em todo membro do workspace com suíte
''';

Future<void> main(List<String> argumentos) async {
  if (argumentos.isEmpty) {
    stdout.write(_uso);
    exit(64);
  }

  final comando = argumentos.first;
  final resto = argumentos.skip(1).toList();

  switch (comando) {
    case 'fontes':
      exit(
        _validar(
          validarFontes(acharRaiz()),
          'fontes',
          'catálogo e redirecionamentos OK',
        ),
      );
    case 'comentarios':
      exit(
        _validar(
          validarComentarios(acharRaiz()),
          'comentarios',
          'nenhum comentário proibido',
        ),
      );
    case 'readme':
      exit(_readme(checar: resto.contains('--check')));
    case 'diario':
      exit(_diario(seco: resto.contains('--dry-run')));
    case 'test':
      exit(await rodarTestes(acharRaiz()));
    case 'log-backup':
      exit(salvarLog(acharRaiz()));
    case 'refs-claude':
      exit(await baixarReferencias(acharRaiz()));
    case 'statusline':
      stdout.write(montarStatusline(_lerStdin()));
      exit(0);
    case 'hook-prompt':
      _hook(hookPrompt);
    case 'hook-answer':
      _hook(hookResposta);
    case 'hook-stop':
      _hook(hookPortao);
    default:
      stderr.write('harness: comando desconhecido "$comando"\n\n$_uso');
      exit(64);
  }
}

int _validar(List<String> erros, String rotulo, String sucesso) {
  if (erros.isEmpty) {
    stdout.writeln('✅ $rotulo: $sucesso');
    return 0;
  }
  stderr.writeln('❌ $rotulo: ${erros.length} problema(s)');
  for (final erro in erros) {
    stderr.writeln('   • $erro');
  }
  return 1;
}

int _readme({required bool checar}) {
  final raiz = acharRaiz();
  final arquivo = File('${raiz.path}/README.md');

  try {
    if (!arquivo.existsSync()) {
      if (checar) {
        stderr.writeln('❌ readme: README.md não existe. Rode `just readme`');
        return 1;
      }
      arquivo.writeAsStringSync(renderizar(raiz, esqueleto()));
      stdout.writeln('✅ readme: criado a partir do esqueleto');
      return 0;
    }

    final atual = arquivo.readAsStringSync();
    final novo = renderizar(raiz, atual);

    if (atual == novo) {
      stdout.writeln('✅ readme: em dia com as fontes de verdade');
      return 0;
    }
    if (checar) {
      stderr.writeln('❌ readme: desatualizado. Rode `just readme`.');
      return 1;
    }
    arquivo.writeAsStringSync(novo);
    stdout.writeln('✅ readme: atualizado');
    return 0;
  } on FonteAusente catch (erro) {
    stderr.writeln('❌ readme: $erro');
    return 1;
  }
}

int _diario({required bool seco}) {
  final raiz = acharRaiz();
  final pagina = montarPagina(raiz);
  if (seco) {
    stdout
      ..write(pagina.corpo)
      ..writeln(
        '\n--- (dry-run) seria ${pagina.nome} '
        'em ${pagina.wiki ?? '<sem origin>'}',
      );
    return 0;
  }
  stdout.writeln(publicar(raiz, pagina));
  return 0;
}

void _hook(RespostaDeHook Function(String) tratador) {
  final bruto = _lerStdin();
  RespostaDeHook resposta;
  try {
    resposta = tratador(bruto);
  } on FormatException {
    exit(0);
  } on FileSystemException {
    exit(0);
  }
  final json = resposta.json;
  if (json != null) stdout.write(json);
  exit(0);
}

String _lerStdin() {
  final buffer = StringBuffer();
  while (true) {
    final linha = stdin.readLineSync(encoding: utf8);
    if (linha == null) break;
    buffer.writeln(linha);
  }
  return buffer.toString();
}
