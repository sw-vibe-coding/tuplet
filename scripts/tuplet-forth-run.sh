#!/usr/bin/env bash
#
# tuplet-forth-run.sh -- assemble Tuplet-emitted Forth and run it on
# the sw-cor24-forth kernel under cor24-run.
#
# Usage:
#   tuplet-forth-run.sh <basename> <forth-emit-driver.ml>
#
# Pipeline:
#   1. Compile + run the OCaml driver chain (ast -> ... -> forth_emit)
#      via run-ml.sh to get the deterministic `FORTH ... ENDFORTH`
#      dump.
#   2. Strip the `FORTH` / `BODY` / `ENDFORTH` markers, leaving the
#      bare emitted Forth.
#   3. Concatenate `prelude/tuplet-prelude.fs` (skipping comment-only
#      lines) with the emitted body into `work/generated/<basename>.fs`.
#   4. Pipe the .fs content through cor24-run via UART input, capturing
#      the post-`UART output:` lines as the program output.
#
# Errors out non-zero if the OCaml driver fails or the emitter output
# is malformed.
#
set -euo pipefail

(( $# == 2 )) || {
  echo "usage: tuplet-forth-run.sh <basename> <forth-emit-driver.ml>" >&2
  exit 1
}

basename="$1"
driver="$2"

repo="/Users/mike/github/sw-vibe-coding/tuplet"
prelude="${repo}/prelude/tuplet-prelude.fs"
generated_dir="${repo}/work/generated"
forth_kernel="${HOME}/github/sw-embed/sw-cor24-forth/forth.s"

[ -r "${driver}" ]       || { echo "tuplet-forth-run.sh: cannot read ${driver}" >&2; exit 2; }
[ -r "${prelude}" ]      || { echo "tuplet-forth-run.sh: missing prelude ${prelude}" >&2; exit 2; }
[ -r "${forth_kernel}" ] || { echo "tuplet-forth-run.sh: missing kernel ${forth_kernel}" >&2; exit 2; }

mkdir -p "${generated_dir}"
fs_path="${generated_dir}/${basename}.fs"

# Step 1: run the OCaml driver chain.
emit_raw="$(bash "${repo}/scripts/run-ml.sh" \
  "${repo}/src/ast.ml" \
  "${repo}/src/registry.ml" \
  "${repo}/src/parser.ml" \
  "${repo}/src/checker.ml" \
  "${repo}/src/ir.ml" \
  "${repo}/src/forth_emit.ml" \
  "${driver}")"

# Step 2: strip FORTH / BODY / ENDFORTH markers; refuse silently-malformed.
case "${emit_raw}" in
  FORTH$'\n'*ENDFORTH*) ;;
  *)
    echo "tuplet-forth-run.sh: emitter output missing FORTH/ENDFORTH markers" >&2
    printf '%s\n' "${emit_raw}" >&2
    exit 3
    ;;
esac

emitted="$(printf '%s\n' "${emit_raw}" |
  sed -e '1{/^FORTH$/d;}' -e '/^BODY$/d' -e '/^ENDFORTH$/d')"

# Step 3: write prelude (sans pure-comment lines) followed by emitted body.
{
  grep -vE '^(\\$|\\ )' "${prelude}" || true
  printf '%s\n' "${emitted}"
} > "${fs_path}"

# Step 4: feed each non-empty line through UART, capture post-`UART output:` text.
uart_input="$(awk 'NF { print $0 }' "${fs_path}")"
uart_input+=$'\n'

cor24_out="$(cor24-run --run "${forth_kernel}" \
  -u "${uart_input}" \
  --speed 0 -n 50000000 2>&1)"

printf '%s\n' "${cor24_out}" |
  awk '/^UART output:/{flag=1} flag{print}'
