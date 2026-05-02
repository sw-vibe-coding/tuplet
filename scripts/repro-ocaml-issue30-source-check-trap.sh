#!/usr/bin/env bash
set -euo pipefail

# Repro for the remaining Tuplet real-source checker handoff failure
# after sw-embed/sw-cor24-ocaml#30 fixed the allocation-after-parse case.
#
# Expected: checker output equivalent to tuplet_check_parse_tuple_assign_pass.
# Current on sw-cor24-ocaml 7cbe291: TRAP 2.

repo="/Users/mike/github/sw-vibe-coding/tuplet"
bash "${repo}/scripts/run-lex-check-fixture.sh" \
  "${repo}/tests/checker/source_tuple_assign.input"
