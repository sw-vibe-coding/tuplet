#!/usr/bin/env bash
set -euo pipefail

repo="/Users/mike/github/sw-vibe-coding/tuplet"
bash "${repo}/scripts/run-ml-memory.sh" \
  "${repo}/tests/parser/lex_parse_signature.input" \
  "${repo}/src/ast.ml" \
  "${repo}/src/registry.ml" \
  "${repo}/src/parser.ml" \
  "${repo}/src/lexer.ml" \
  "${repo}/src/lex_bridge.ml" \
  "${repo}/src/checker.ml" \
  "${repo}/src/lex_parse_alloc_after_main.ml"
