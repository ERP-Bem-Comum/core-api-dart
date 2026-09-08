harness := "build/harness"

# Lista as tarefas disponíveis
default:
    @just --list

# ---------------------------------------------------------------- portão --

# Portão de verificação — precisa passar antes de considerar qualquer trabalho pronto
check: fmt-check analyze test fontes comentarios readme-check
    @echo "✅ portão verde"

# Formatação — falha se algum arquivo estiver fora do padrão
fmt-check: deps
    @dart format --set-exit-if-changed --output=none .

# Análise estática
analyze: deps
    @dart analyze --fatal-infos

# Testes de todo membro do workspace que tenha suíte
test: build-harness
    @{{harness}} test

# Resolve as dependências do workspace se ainda não estiverem
deps:
    @test -f .dart_tool/package_config.json || dart pub get

# Compila o executável do harness em build/harness quando o fonte é mais novo
build-harness: deps
    @mkdir -p "$(dirname {{harness}})"
    @test -x {{harness}} && test -z "$(find tool/harness -name '*.dart' -newer {{harness}} -print -quit)" || dart compile exe tool/harness/bin/harness.dart -o {{harness}} >&2

# Valida as duas fontes por lib e o _FONTES.md por área de documentação
fontes: build-harness
    @{{harness}} fontes

# Valida a regra de comentários em Dart e em configuração
comentarios: build-harness
    @{{harness}} comentarios

# Reprova se o README divergir das fontes de verdade
readme-check: build-harness
    @{{harness}} readme --check

# ---------------------------------------------------------------- gerados --

# Regenera os blocos automáticos do README a partir das fontes de verdade
readme: build-harness
    @{{harness}} readme

# --------------------------------------------------------------- formato --

# Formata o código
fmt:
    @dart format .

# ----------------------------------------------------------------- skills --

# Instala/atualiza as skills publicadas pelas dependências, em .agents/skills/
skills:
    @dart run skills@ get --all

# Lista as skills de package instaladas neste projeto
skills-list:
    @dart run skills@ list

# Remove skills de dependências que saíram do pubspec
skills-prune:
    @dart run skills@ prune

# ------------------------------------------------------------- diário IA --

# Publica na wiki a página do diário com os commits e prompts do período
diario: build-harness
    @{{harness}} diario

# Mostra a página do diário sem publicar
diario-seco: build-harness
    @{{harness}} diario --dry-run

# Salva o .ai-log fora do repositório, mantendo as 10 cópias mais recentes
log-backup: build-harness
    @{{harness}} log-backup

# Instala os hooks de git de .githooks/ (pre-push publica o diário)
hooks-git:
    @git config core.hooksPath .githooks && echo "✅ core.hooksPath = .githooks"

# ---------------------------------------------------- referência (último) --

# FALLBACK: baixa a doc do Claude Code/API para disco (gitignorada — posição 6)
refs-claude: build-harness
    @{{harness}} refs-claude

# Executa o harness garantindo que o binário exista (usado pelos hooks)
[private]
h *args: build-harness
    @{{harness}} {{args}}
