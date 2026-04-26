#!/usr/bin/env bash
#
# run-ml.sh -- run a .ml file via sw-cor24-ocaml and emit only the
# program's output. Strips the Pascal runtime's "> <source-line>"
# echo prefixes that precede actual program output.
#
# As of sw-embed/sw-cor24-ocaml#3, multi-line source files are
# supported with persistent top-level let declarations, and the
# runtime echoes each top-level statement separately. The strip
# uses perl literal substitution (\Q...\E) per source line so
# parens/brackets in the source don't trip up regex specials.
#
# Usage: run-ml.sh <path/to/file.ml>
#
set -euo pipefail

src_path="${1:?usage: run-ml.sh <path/to/file.ml>}"
[ -r "${src_path}" ] || { echo "run-ml.sh: cannot read ${src_path}" >&2; exit 2; }

raw="$(bash "${HOME}/github/sw-embed/sw-cor24-ocaml/scripts/run-ocaml.sh" "${src_path}")"

# For each source line, strip one occurrence of "> <line>" plus
# optional trailing newline. Skips blank source lines.
clean="$(printf '%s' "${raw}" | perl -e '
my $raw;
{ local $/; $raw = <STDIN>; }
open(my $fh, "<", $ARGV[0]) or die "cannot open $ARGV[0]: $!";
while (my $line = <$fh>) {
    chomp $line;
    next if $line eq "";
    $raw =~ s/\Q> $line\E\n?//;
}
print $raw;
' "${src_path}")"

printf '%s\n' "${clean}"
