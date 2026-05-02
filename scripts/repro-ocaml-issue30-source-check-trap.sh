#!/usr/bin/env bash
set -euo pipefail

# Regression check for the Tuplet real-source checker handoff failure
# fixed by sw-embed/sw-cor24-ocaml#30 and Tuplet's call-stack patches.
#
# Expected: checker output equivalent to tuplet_check_parse_tuple_assign_pass.

repo="/Users/mike/github/sw-vibe-coding/tuplet"
bash "${repo}/scripts/run-lex-check-fixture.sh" \
  "${repo}/tests/checker/source_tuple_assign.input"
