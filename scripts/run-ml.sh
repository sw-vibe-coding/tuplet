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

(( $# >= 1 )) || { echo "usage: run-ml.sh <file1.ml> [file2.ml ...]" >&2; exit 1; }
for p in "$@"; do
  [ -r "${p}" ] || { echo "run-ml.sh: cannot read ${p}" >&2; exit 2; }
done

raw="$(bash "${HOME}/github/sw-embed/sw-cor24-ocaml/scripts/run-ocaml.sh" "$@")"

# For each line of every source file, strip one occurrence of
# "> <line>" plus optional trailing newline. The runtime also
# emits an internal `let __module = "..."` line per multi-file
# unit; strip that too. Skips blank source lines.
clean="$(printf '%s' "${raw}" | perl -e '
my $raw;
{ local $/; $raw = <STDIN>; }
for my $path (@ARGV) {
  open(my $fh, "<", $path) or die "cannot open $path: $!";
  while (my $line = <$fh>) {
      chomp $line;
      next if $line eq "";
      $raw =~ s/\Q> $line\E\n?//;
  }
}
$raw =~ s/^> let __module = "[^"]*"\n//gm;
print $raw;
' "$@")"

printf '%s\n' "${clean}"
