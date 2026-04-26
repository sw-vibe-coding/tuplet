#!/usr/bin/env bash
#
# run-lexer-fixture.sh -- run src/lexer.ml against a fixture file.
#
# Feeds the fixture's bytes (including the trailing ETX 0x03 EOF
# sentinel) via OCAML_STDIN. Strips runtime source-echo prefixes
# using the same greedy-match approach as scripts/run-ml.sh, so
# multi-line `match` and `let ... in` constructs (which the
# runtime joins onto a single echo line) are handled correctly.
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

my @src_lines;
open(my $fh, "<", $ARGV[0]) or die "cannot open $ARGV[0]: $!";
while (my $line = <$fh>) {
    chomp $line;
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    push @src_lines, $line if $line ne "";
}
close $fh;
my @by_len = sort { length($b) <=> length($a) } @src_lines;

my $out = "";
for my $line (split /\n/, $raw, -1) {
    if ($line =~ /^let __module = "[^"]*"$/) {
        next;
    }
    if ($line =~ /^> /) {
        my $rest = substr($line, 2);
        my $stripped = 1;
        while ($stripped && $rest ne "") {
            $stripped = 0;
            $rest =~ s/^\s+//;
            for my $src (@by_len) {
                if (length($rest) >= length($src) &&
                    substr($rest, 0, length($src)) eq $src) {
                    $rest = substr($rest, length($src));
                    $stripped = 1;
                    last;
                }
            }
        }
        $rest =~ s/^\s+//;
        $out .= $rest . "\n" if $rest ne "";
    } else {
        $out .= $line . "\n";
    }
}
$out =~ s/\n+$/\n/;
print $out;
' "${src_path}")"

printf '%s\n' "${clean}"
