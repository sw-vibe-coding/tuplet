#!/usr/bin/env bash
#
# run-ml.sh -- run one or more .ml files via sw-cor24-ocaml and
# emit only the program's output. Strips the Pascal runtime's
# "> <echoed-source>" prefixes that precede actual output.
#
# The runtime echoes each top-level expression on its own
# line. For multi-line constructs (e.g., a `match` whose arms
# span multiple lines), the runtime joins them into one echoed
# line; the strip therefore needs to greedily consume any
# concatenation of source lines from the echo prefix, not
# match per source line individually.
#
# Usage: run-ml.sh <file1.ml> [file2.ml ...]
#
set -euo pipefail

(( $# >= 1 )) || { echo "usage: run-ml.sh <file1.ml> [file2.ml ...]" >&2; exit 1; }
for p in "$@"; do
  [ -r "${p}" ] || { echo "run-ml.sh: cannot read ${p}" >&2; exit 2; }
done

raw="$(bash "${HOME}/github/sw-embed/sw-cor24-ocaml/scripts/run-ocaml.sh" "$@")"

# Strip echoes. For each raw output line:
#   - If it starts with "> ": treat as runtime echo prefix.
#     Greedily strip the longest possible source-line content
#     from the start (consumes joined multi-line constructs).
#     Whatever remains after stripping is program output.
#   - Otherwise: keep as program output.
#
# Also strip the runtime's internal `let __module = "..."`
# echoes that appear when multiple files are compiled together.
clean="$(printf '%s' "${raw}" | perl -e '
my $raw;
{ local $/; $raw = <STDIN>; }

my @src_lines;
for my $path (@ARGV) {
    open(my $fh, "<", $path) or die "cannot open $path: $!";
    while (my $line = <$fh>) {
        chomp $line;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        push @src_lines, $line if $line ne "";
    }
    close $fh;
}
# Try longest first so multi-word source lines have priority.
my @by_len = sort { length($b) <=> length($a) } @src_lines;

my $out = "";
for my $line (split /\n/, $raw, -1) {
    if ($line =~ /^let __module = "[^"]*"$/) {
        next;  # runtime internal
    }
    if ($line =~ /^> /) {
        my $rest = substr($line, 2);
        # Greedily strip source-line prefixes (with optional
        # leading whitespace between concatenations).
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
' "$@")"

printf '%s\n' "${clean}"
