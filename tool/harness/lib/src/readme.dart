import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

import 'fontes.dart';

const _abre =
    '<!-- gerado:{nome} — NÃO EDITE À MÃO; saída de `just readme` -->';
const _fecha = '<!-- /gerado:{nome} -->';

const _blocos = <String>['toolchain', 'tarefas', 'packages', 'regras', 'docs'];

/// Uma fonte de verdade do README sumiu ou está malformada.
class FonteAusente implements Exception {
  const FonteAusente(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

/// Reescreve os blocos marcados do README com o estado atual do repositório.
///
/// A prosa fora dos marcadores não é tocada. Cria o arquivo a partir de um
/// esqueleto quando ele ainda não existe.
String renderizar(Directory raiz, String atual) {
  var texto = atual;
  for (final nome in _blocos) {
    final abre = _abre.replaceAll('{nome}', nome);
    final fecha = _fecha.replaceAll('{nome}', nome);
    final padrao = RegExp(
      '${RegExp.escape(abre)}[\\s\\S]*?${RegExp.escape(fecha)}',
    );
    if (!padrao.hasMatch(texto)) {
      throw FonteAusente(
        'README.md sem o bloco `$nome`. Apague o README.md e rode '
        '`just readme` para recriar a partir do esqueleto',
      );
    }
    texto = texto.replaceFirst(
      padrao,
      '$abre\n\n${_conteudo(raiz, nome)}\n\n$fecha',
    );
  }
  return texto;
}

String esqueleto() {
  final buffer = StringBuffer('''
# core-api-dart

Backend Dart do **bem_comum** (ERP Financeiro): monolito modular em pub workspaces,
um package por bounded context, arquitetura hexagonal, fatia vertical primeiro.

> **Estado.** O código de aplicação ainda **não existe**. O que está montado é o
> harness: regras, hooks de registro, portão de verificação e memória de agentes.
''');
  const titulos = <String, String>{
    'toolchain': 'Como começar',
    'tarefas': 'Tarefas',
    'packages': 'Bounded contexts',
    'regras': 'Onde estão as decisões',
    'docs': 'Documentação',
  };
  for (final nome in _blocos) {
    buffer
      ..writeln('\n## ${titulos[nome]}\n')
      ..writeln(_abre.replaceAll('{nome}', nome))
      ..writeln()
      ..writeln()
      ..writeln(_fecha.replaceAll('{nome}', nome));
  }
  buffer.write('''
---

As seções entre marcadores `<!-- gerado:… -->` são saída de `just readme`. Para mudar
o que elas dizem, mude a fonte de verdade; `just check` reprova o README desatualizado.
''');
  return buffer.toString();
}

String _conteudo(Directory raiz, String nome) => switch (nome) {
  'toolchain' => _toolchain(raiz),
  'tarefas' => _tarefas(raiz),
  'packages' => _packages(raiz),
  'regras' => _regras(raiz),
  'docs' => _docs(raiz),
  _ => throw FonteAusente('bloco desconhecido: $nome'),
};

String _tabela(
  List<String> cabecalho,
  List<List<String>> linhas,
  String legenda,
) {
  final buffer = StringBuffer()
    ..writeln('| ${cabecalho.join(' | ')} |')
    ..writeln('|${List.filled(cabecalho.length, '---').join('|')}|');
  for (final linha in linhas) {
    buffer.writeln('| ${linha.join(' | ')} |');
  }
  buffer.write('\n> **Legenda.** $legenda');
  return buffer.toString();
}

YamlMap? _yaml(File arquivo) {
  if (!arquivo.existsSync()) return null;
  final conteudo = loadYaml(arquivo.readAsStringSync());
  return conteudo is YamlMap ? conteudo : null;
}

String _toolchain(Directory raiz) {
  final pubspec = _yaml(File('${raiz.path}/pubspec.yaml'));
  final linhas = <List<String>>[];

  final ambiente = pubspec?['environment'];
  final sdk = ambiente is YamlMap ? ambiente['sdk'] : null;
  linhas.add(
    sdk is String
        ? ['Dart SDK', '`$sdk`', '`pubspec.yaml` → `environment.sdk`']
        : ['Dart SDK', '_não declarado_', '`pubspec.yaml`'],
  );

  linhas
    ..add(['`just`', 'task runner', '`Justfile` — ponto único de entrada'])
    ..add([
      '`harness`',
      'hooks e validadores, um executável',
      '`tool/harness/` → `build/harness`',
    ]);

  final ci = File('${raiz.path}/.github/workflows/ci.yml');
  linhas.add([
    'CI',
    ci.existsSync() ? 'GitHub Actions' : '_ausente_',
    '`.github/workflows/ci.yml`',
  ]);

  final catalogo = loadYaml(
    File('${raiz.path}/docs/fontes.yaml').readAsStringSync(),
  );
  if (catalogo is YamlList) {
    for (final entrada in catalogo) {
      if (entrada is YamlMap && entrada['nome'] == 'postgresql') {
        linhas.add(['Banco', '${entrada['usada_para']}', '`docs/fontes.yaml`']);
        break;
      }
    }
  }

  final corpo = _tabela(
    const ['Peça', 'O quê', 'Onde está declarado'],
    linhas,
    '*Declarado* é o que o repositório exige, não o que está instalado na sua '
    'máquina — a versão local varia por máquina e não vale como contrato.',
  );

  return '$corpo\n\n```sh\n'
      'just --list   # descobre as tarefas\n'
      'just check    # o portão: rode antes de considerar trabalho pronto\n'
      '```';
}

String _tarefas(Directory raiz) {
  final resultado = Process.runSync('just', const [
    '--dump',
    '--dump-format',
    'json',
  ], workingDirectory: raiz.path);
  if (resultado.exitCode != 0) {
    throw FonteAusente('`just --dump` falhou: ${resultado.stderr}');
  }

  final json = jsonDecode(resultado.stdout.toString());
  final receitas = (json as Map<String, Object?>)['recipes'];
  if (receitas is! Map<String, Object?>) {
    throw FonteAusente('`just --dump` não trouxe receitas');
  }

  final nomes = receitas.keys.toList()..sort();
  final linhas = <List<String>>[];
  for (final nome in nomes) {
    final receita = receitas[nome];
    if (receita is! Map<String, Object?>) continue;
    if (receita['private'] == true || nome == 'default') continue;

    final dependencias = receita['dependencies'];
    final chamadas = <String>[];
    if (dependencias is List) {
      for (final d in dependencias) {
        if (d is Map<String, Object?> && d['recipe'] is String) {
          chamadas.add('`${d['recipe']}`');
        }
      }
    }
    final doc = receita['doc'];
    linhas.add([
      '`just $nome`',
      doc is String ? doc : '_sem descrição_',
      chamadas.isEmpty ? '—' : chamadas.join(', '),
    ]);
  }

  return _tabela(
    const ['Tarefa', 'O que faz', 'Chama antes'],
    linhas,
    '*Chama antes* são as receitas executadas como pré-requisito. `just check` '
    'é o portão: o hook `Stop` e o CI rodam exatamente esta receita, para que '
    'exista uma só definição de verde.',
  );
}

String _packages(Directory raiz) {
  final pasta = Directory('${raiz.path}/packages');
  final linhas = <List<String>>[];

  if (pasta.existsSync()) {
    final pastas = pasta.listSync().whereType<Directory>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final membro in pastas) {
      final nome = membro.path.split('/').last;
      final pubspec = _yaml(File('${membro.path}/pubspec.yaml'));
      if (pubspec == null) {
        linhas.add(['`$nome`', '⚠️ sem `pubspec.yaml`', '—']);
        continue;
      }
      linhas.add([
        '`${pubspec['name'] ?? nome}`',
        '${pubspec['description'] ?? '_sem descrição_'}',
        '`packages/$nome/`',
      ]);
    }
  }

  if (linhas.isEmpty) {
    return '_Nenhum package ainda._ O código de aplicação não existe; o que '
        'está montado é o harness. Cada bounded context nasce como um package '
        'sob `packages/`, e aparece aqui sozinho a partir do seu `pubspec.yaml`.';
  }

  return _tabela(
    const ['Package', 'Bounded context', 'Caminho'],
    linhas,
    '*Bounded context* é uma fatia do domínio com vocabulário próprio — o mesmo '
    'termo pode significar coisas diferentes em dois contextos, e é isso que '
    'justifica separá-los.',
  );
}

String _regras(Directory raiz) {
  final texto = File('${raiz.path}/CLAUDE.md').readAsStringSync();
  final padrao = RegExp(
    r'^\|\s*`([a-z0-9-]+\.md)`\s*\|\s*(.+?)\s*\|\s*$',
    multiLine: true,
  );
  final achados = padrao.allMatches(texto).toList();
  if (achados.isEmpty) {
    throw const FonteAusente('não achei a tabela de regras no CLAUDE.md');
  }

  final indexadas = achados.map((m) => m[1]!).toSet();
  final noDisco = Directory('${raiz.path}/.claude/rules')
      .listSync()
      .whereType<File>()
      .map((f) => f.path.split('/').last)
      .where((n) => n.endsWith('.md'))
      .toSet();

  final faltando = (noDisco.difference(indexadas).toList())..sort();
  if (faltando.isNotEmpty) {
    throw FonteAusente(
      'regra(s) em .claude/rules/ fora da tabela do CLAUDE.md: '
      '${faltando.join(', ')} — regra fora do índice é regra que ninguém lê',
    );
  }
  final fantasmas = (indexadas.difference(noDisco).toList())..sort();
  if (fantasmas.isNotEmpty) {
    throw FonteAusente(
      'CLAUDE.md lista regra(s) que não existem: ${fantasmas.join(', ')}',
    );
  }

  return _tabela(
    const ['Regra', 'Assunto'],
    [
      for (final m in achados) ['[`${m[1]}`](.claude/rules/${m[1]})', m[2]!],
    ],
    'Estas regras valem para pessoas e para agentes de IA igualmente. O '
    '`CLAUDE.md` na raiz carrega inteiro em toda sessão e aponta para elas.',
  );
}

String _docs(Directory raiz) {
  final catalogo = loadYaml(
    File('${raiz.path}/docs/fontes.yaml').readAsStringSync(),
  );
  if (catalogo is! YamlList || catalogo.isEmpty) {
    throw const FonteAusente('docs/fontes.yaml ausente ou vazio');
  }

  final linhas = <List<String>>[];
  for (final entrada in catalogo) {
    if (entrada is! YamlMap) continue;
    final fontes = entrada['fontes'];
    final tipos = <String>{};
    if (fontes is YamlList) {
      for (final fonte in fontes) {
        if (fonte is YamlMap && fonte['tipo'] is String) {
          tipos.add(fonte['tipo'] as String);
        }
      }
    }
    final ordenados = tipos.toList()
      ..sort(
        (a, b) => tiposDeFonte.indexOf(a).compareTo(tiposDeFonte.indexOf(b)),
      );
    linhas.add([
      '`${entrada['nome']}`',
      '${entrada['usada_para'] ?? ''}',
      ordenados.map((t) => '`$t`').join(' → '),
    ]);
  }

  final corpo = _tabela(
    const ['Lib / ferramenta', 'Usada para', 'Fontes, na ordem de consulta'],
    linhas,
    'A ordem é a cascata: **MCP → `llms.txt` → CLI → fonte crua do pacote → '
    'web → offline**. Doc offline é a última parada porque é uma foto com '
    'data: envelhece sem avisar. Nenhuma lib entra com menos de duas fontes.',
  );

  return '$corpo\n\nCatálogo completo em [`docs/fontes.yaml`](docs/fontes.yaml); '
      'a regra, em [`.claude/rules/documentacao.md`](.claude/rules/documentacao.md). '
      '`just fontes` reprova quem violar.';
}
