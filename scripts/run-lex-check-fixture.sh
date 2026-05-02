#!/usr/bin/env bash
set -euo pipefail

fixture="${1:?usage: run-lex-check-fixture.sh <source.input> [main.ml]}"
main="${2:-/Users/mike/github/sw-vibe-coding/tuplet/src/lex_check_main.ml}"
[ -r "${fixture}" ] || { echo "run-lex-check-fixture.sh: cannot read ${fixture}" >&2; exit 2; }
[ -r "${main}" ] || { echo "run-lex-check-fixture.sh: cannot read ${main}" >&2; exit 2; }

repo="/Users/mike/github/sw-vibe-coding/tuplet"
bash "${repo}/scripts/run-ml-memory.sh" "${fixture}" \
  "${repo}/src/ast.ml" \
  "${repo}/src/registry.ml" \
  "${repo}/src/parser.ml" \
  "${repo}/src/lexer.ml" \
  "${repo}/src/lex_bridge.ml" \
  "${repo}/src/checker.ml" \
  "${main}"
