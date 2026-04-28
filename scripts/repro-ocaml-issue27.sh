#!/usr/bin/env bash
#
# Repro for sw-embed/sw-cor24-ocaml#27.
#
# This intentionally keeps the failing Tuplet stack intact. It runs the
# same memory-backed lexer -> parser handoff that used to pass after #25,
# and now fails while loading the combined Ast/Registry/Parser/Lexer/
# Lex_bridge/Lex_parse_main source set on sw-cor24-ocaml f690558.
#
set -euo pipefail

repo="/Users/mike/github/sw-vibe-coding/tuplet"

echo "== Tuplet commit =="
git -C "${repo}" rev-parse HEAD
echo

echo "== OCaml host commit =="
git -C "${HOME}/github/sw-embed/sw-cor24-ocaml" rev-parse HEAD
echo

echo "== Passing lexer-only control =="
REG_RS_DATA_DIR="${repo}/work/reg-rs" reg-rs run -p tuplet_lex_ident_simple
echo

echo "== Failing full memory-backed handoff =="
bash "${repo}/scripts/run-lex-parse-fixture.sh" "${repo}/tests/parser/lex_parse_assignment.input"
