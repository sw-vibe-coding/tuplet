#!/usr/bin/env bash
#
# Repro for sw-embed/sw-cor24-ocaml#28.
#
# The first memory-backed parser pass registers a syntax declaration.
# A second pass over the same memory input should parse the next source
# line against that registry, but the host traps while lexing that line.
#
set -euo pipefail

repo="/Users/mike/github/sw-vibe-coding/tuplet"
debug_main="$(mktemp "${TMPDIR:-/tmp}/tuplet-issue28-debug.XXXXXX.ml")"
trap 'rm -f "${debug_main}"' EXIT

cat > "${debug_main}" <<'ML'
let _ = print_endline "DEBUG start"
let _ = Lexer.use_memory_input 524288
let _ = Registry.reset_syntax_registry ()
let first = Lex_bridge.parse_line ()
let _ = print_endline "DEBUG first"
let _ = Ast.dump_program first
let _ = print_endline "DEBUG tokens"
let toks = Lexer.lex_loop 0 []
let _ = Lexer.dump_tokens toks
ML

echo "== Tuplet commit =="
git -C "${repo}" rev-parse HEAD
echo

echo "== OCaml host commit =="
git -C "${HOME}/github/sw-embed/sw-cor24-ocaml" rev-parse HEAD
echo

echo "== Passing one-pass assignment control =="
REG_RS_DATA_DIR="${repo}/work/reg-rs" reg-rs run -p tuplet_parse_memory_assignment
echo

echo "== Failing two-pass syntax registration repro =="
bash "${repo}/scripts/run-ml-memory.sh" \
  "${repo}/tests/parser/lex_parse_syntax.input" \
  "${repo}/src/ast.ml" \
  "${repo}/src/registry.ml" \
  "${repo}/src/parser.ml" \
  "${repo}/src/lexer.ml" \
  "${repo}/src/lex_bridge.ml" \
  "${debug_main}"
