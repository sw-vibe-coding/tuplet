#!/usr/bin/env bash
#
# run-ml.sh -- run a .ml file via sw-cor24-ocaml and emit only the
# program's output. Strips the Pascal runtime's "> <source-line>"
# echo prefixes that precede actual program output.
#
# Usage: run-ml.sh <path/to/file.ml>
#
set -euo pipefail

src_path="${1:?usage: run-ml.sh <path/to/file.ml>}"
[ -r "${src_path}" ] || { echo "run-ml.sh: cannot read ${src_path}" >&2; exit 2; }

raw="$(bash "${HOME}/github/sw-embed/sw-cor24-ocaml/scripts/run-ocaml.sh" "${src_path}")"

# Build the expected echo prefix: each source line prepended with "> ",
# concatenated without separators. The runtime emits the prefix as a
# single block, then the program output begins with no intervening
# newline on the join line.
expected=""
while IFS= read -r line || [ -n "${line}" ]; do
    expected+="> ${line}"
done < "${src_path}"

# Use literal length-based strip rather than ${var#pattern}: the
# expected prefix contains parens, brackets, and other glob specials
# that ${var#pat} would interpret as a pattern.
exp_len=${#expected}
if [ ${#raw} -ge "${exp_len}" ] && [ "${raw:0:${exp_len}}" = "${expected}" ]; then
    raw="${raw:${exp_len}}"
fi

printf '%s\n' "${raw}"
