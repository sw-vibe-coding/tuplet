#!/usr/bin/env bash
#
# repro-cor24-forth-create-variable.sh -- reproduce the sw-cor24-forth
# CREATE / variable-cell limitation that blocks Tuplet's tuple-cell
# lowering (`docs/lowering.md`).
#
# Expected (per ANS / our docs/lowering.md): after `CREATE foo 42 ,`,
# the word `foo` pushes its data-field address; `foo @` returns 42.
#
# Actual on sw-cor24-forth `forth.s` (commit at HEAD as of 2026-05-08):
# `foo` pushes nothing; subsequent `@` then `.` errors with `?` and
# the program does not produce the expected `42`.
#
# Use this script to reproduce locally and to attach to the upstream
# issue. The script does NOT modify any sibling repo.
#
set -euo pipefail

forth_kernel="${HOME}/github/sw-embed/sw-cor24-forth/forth.s"
[ -r "${forth_kernel}" ] || {
  echo "missing kernel: ${forth_kernel}" >&2
  exit 2
}

input=$'CREATE foo 42 ,\nfoo .S\nfoo @ .\n'

echo "=== input ==="
printf '%s' "${input}"
echo "=== output (post-UART output:) ==="
cor24-run --run "${forth_kernel}" -u "${input}" --speed 0 -n 50000000 2>&1 |
  awk '/^UART output:/{flag=1} flag{print}'
