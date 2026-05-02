#!/usr/bin/env bash
set -euo pipefail

fixture="${1:?usage: run-lex-ir-fixture.sh <source.input>}"
[ -r "${fixture}" ] || { echo "run-lex-ir-fixture.sh: cannot read ${fixture}" >&2; exit 2; }

repo="/Users/mike/github/sw-vibe-coding/tuplet"
bash "${repo}/scripts/run-ml-memory.sh" "${fixture}" \
  "${repo}/src/ast.ml" \
  "${repo}/src/registry.ml" \
  "${repo}/src/parser.ml" \
  "${repo}/src/lexer.ml" \
  "${repo}/src/lex_bridge.ml" \
  "${repo}/src/checker.ml" \
  "${repo}/src/ir.ml" \
  "${repo}/src/lex_ir_main.ml"
