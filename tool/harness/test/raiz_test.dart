import 'dart:io';

import 'package:harness/src/raiz.dart';
import 'package:test/test.dart';

void main() {
  late Directory temporaria;

  setUp(() {
    temporaria = Directory.systemTemp.createTempSync('harness-raiz');
    File('${temporaria.path}/Justfile').writeAsStringSync('default:\n');
  });

  tearDown(() => temporaria.deleteSync(recursive: true));

  test('caminho explícito vence CLAUDE_PROJECT_DIR', () {
    expect(
      Platform.environment['CLAUDE_PROJECT_DIR'],
      isNotNull,
      reason:
          'o portão roda os testes com a variável definida, como o hook '
          'faz; sem ela este teste não prova a precedência',
    );

    final achada = acharRaiz(temporaria.path);
    expect(
      achada.resolveSymbolicLinksSync(),
      temporaria.resolveSymbolicLinksSync(),
    );
  });

  test('sobe até o Justfile a partir de uma subpasta', () {
    final funda = Directory('${temporaria.path}/a/b/c')
      ..createSync(recursive: true);
    expect(
      acharRaiz(funda.path).resolveSymbolicLinksSync(),
      temporaria.resolveSymbolicLinksSync(),
    );
  });

  test('lança quando não há Justfile acima', () {
    final orfa = Directory.systemTemp.createTempSync('harness-orfa');
    addTearDown(() => orfa.deleteSync(recursive: true));
    expect(() => acharRaiz(orfa.path), throwsA(isA<StateError>()));
  });
}
