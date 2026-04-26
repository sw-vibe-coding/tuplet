#!/usr/bin/env bash
#
# run-lexer-fixture.sh -- run src/lexer.ml against a fixture file.
#
# The fixture file's bytes (including the trailing ETX 0x03 sentinel
# that signals EOF to the lexer) are fed via OCAML_STDIN. Output is
# stripped of the Pascal runtime's "> <source-line>" echoes via
# scripts/run-ml.sh-style perl substitution, so reg-rs sees only
# the lexer's emitted tokens.
#
# Usage: run-lexer-fixture.sh <path/to/fixture.input>
#
set -euo pipefail

fixture="${1:?usage: run-lexer-fixture.sh <fixture.input>}"
[ -r "${fixture}" ] || { echo "run-lexer-fixture.sh: cannot read ${fixture}" >&2; exit 2; }

src_path="/Users/mike/github/sw-vibe-coding/tuplet/src/lexer.ml"
[ -r "${src_path}" ] || { echo "run-lexer-fixture.sh: cannot read ${src_path}" >&2; exit 2; }

raw="$(OCAML_STDIN="$(cat "${fixture}")" bash "${HOME}/github/sw-embed/sw-cor24-ocaml/scripts/run-ocaml.sh" "${src_path}")"

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
