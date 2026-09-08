import 'package:harness/src/redator.dart';
import 'package:test/test.dart';

void main() {
  group('redigir não toca no que é seguro', () {
    test('texto limpo passa íntegro', () {
      const texto = 'roda o just check e me mostra a saída';
      final resultado = redigir(texto);
      expect(resultado.texto, texto);
      expect(resultado.houveDeteccao, isFalse);
    });

    test('a convenção [SECRET:NOME] passa intacta', () {
      const texto = 'conecta com a [SECRET:PG_STAGING_URL] por favor';
      final resultado = redigir(texto);
      expect(resultado.texto, texto);
      expect(resultado.houveDeteccao, isFalse);
    });

    test('referência a variável de ambiente não é credencial', () {
      const texto = r'API_KEY=$UMBLER_API_KEY';
      expect(redigir(texto).houveDeteccao, isFalse);
    });

    test('placeholder não é credencial', () {
      expect(redigir('API_KEY=xxxxxxxxxxxxxxxx').houveDeteccao, isFalse);
      expect(redigir('TOKEN=your-token-here').houveDeteccao, isFalse);
    });
  });

  group('redigir remove credencial real', () {
    test('AWS access key id', () {
      final resultado = redigir('AWS=AKIAIOSFODNN7EXAMPLE');
      expect(resultado.houveDeteccao, isTrue);
      expect(resultado.texto, contains('[REDIGIDO:'));
      expect(resultado.texto, isNot(contains('AKIAIOSFODNN7EXAMPLE')));
    });

    test('token do GitHub', () {
      final segredo = 'ghp_${'a' * 36}';
      final resultado = redigir('meu token é $segredo');
      expect(resultado.houveDeteccao, isTrue);
      expect(resultado.texto, isNot(contains(segredo)));
    });

    test('senha embutida em URL', () {
      final resultado = redigir('postgres://user:s3nh4Secreta@host:5432/db');
      expect(resultado.houveDeteccao, isTrue);
      expect(resultado.texto, isNot(contains('s3nh4Secreta')));
    });

    test('header de autorização', () {
      final resultado = redigir('Authorization: Bearer ${'x' * 40}');
      expect(resultado.houveDeteccao, isTrue);
      expect(resultado.texto, contains('[REDIGIDO]'));
    });

    test('chave privada em bloco PEM', () {
      final resultado = redigir(
        '-----BEGIN RSA PRIVATE KEY-----\nMIIabc\n-----END RSA PRIVATE KEY-----',
      );
      expect(resultado.houveDeteccao, isTrue);
      expect(resultado.texto, contains('[REDIGIDO: chave privada]'));
      expect(resultado.texto, isNot(contains('MIIabc')));
    });

    test('atribuição com valor literal longo', () {
      final resultado = redigir('CLIENT_SECRET=a1b2c3d4e5f6g7h8i9j0');
      expect(resultado.houveDeteccao, isTrue);
      expect(resultado.texto, isNot(contains('a1b2c3d4e5f6g7h8i9j0')));
    });
  });
}
