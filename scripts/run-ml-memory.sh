#!/usr/bin/env bash
#
# run-ml-memory.sh -- run .ml files via sw-cor24-ocaml with a memory image.
#
# Usage: run-ml-memory.sh <image.bin> <file1.ml> [file2.ml ...]
#
set -euo pipefail

(( $# >= 2 )) || { echo "usage: run-ml-memory.sh <image.bin> <file1.ml> [file2.ml ...]" >&2; exit 1; }

image="$1"
shift
[ -r "${image}" ] || { echo "run-ml-memory.sh: cannot read ${image}" >&2; exit 2; }
for p in "$@"; do
  [ -r "${p}" ] || { echo "run-ml-memory.sh: cannot read ${p}" >&2; exit 2; }
done

input_image="$(mktemp "${TMPDIR:-/tmp}/tuplet-memory-input.XXXXXX")"
trap 'rm -f "${input_image}"' EXIT
cp "${image}" "${input_image}"
printf '\003' >> "${input_image}"

repo="/Users/mike/github/sw-vibe-coding/tuplet"
ocaml_repo="${HOME}/github/sw-embed/sw-cor24-ocaml"
build_dir="${ocaml_repo}/build"
cor24_run="${ocaml_repo}/vendor/sw-em24/$(. "${ocaml_repo}/vendor/active.env" && echo "${SW_EM24_VERSION}")/bin/cor24-run"
if [ ! -f "${cor24_run}" ]; then cor24_run="$(command -v cor24-run 2>/dev/null || true)"; fi
[ -n "${cor24_run}" ] || { echo "run-ml-memory.sh: cor24-run not found" >&2; exit 2; }
cor24_wall_seconds="${TUPLET_COR24_WALL_SECONDS:-180}"

module_name_for_file() {
  local path base stem first rest
  path="$1"
  base="$(basename "${path}")"
  stem="${base%.ml}"
  first="${stem:0:1}"
  rest="${stem:1}"
  printf '%s%s' "$(tr '[:lower:]' '[:upper:]' <<< "${first}")" "${rest}"
}

source_for_repl() {
  awk '
    function emit_logical(line) {
      if (line ~ /^[[:space:]]*$/) return
      if (line ~ /^[[:space:]]+/ || line ~ /^and[[:space:]]/) {
        if (have) {
          sub(/^[[:space:]]*/, "", line)
          current = current " " line
        } else {
          current = line
          have = 1
        }
        return
      }
      if (have) print current
      current = line
      have = 1
    }
    {
      out = ""
      in_string = 0
      esc = 0
      for (i = 1; i <= length($0); i++) {
        c = substr($0, i, 1)
        n = substr($0, i + 1, 1)
        if (depth > 0) {
          if (c == "(" && n == "*") { depth++; i++ }
          else if (c == "*" && n == ")") { depth--; i++ }
          continue
        }
        if (in_string) {
          out = out c
          if (esc) esc = 0
          else if (c == "\\") esc = 1
          else if (c == "\"") in_string = 0
          continue
        }
        if (c == "\"") { out = out c; in_string = 1; continue }
        if (c == "(" && n == "*") { depth = 1; i++; continue }
        out = out c
      }
      emit_logical(out)
    }
    END {
      if (have) print current
      if (depth > 0) exit 2
    }
  ' "$1"
}

code_ptr="$(cat "${build_dir}/code_ptr_addr.txt")"
heap_limit="$(cat "${build_dir}/heap_limit_addr.txt")"

ml_input=""
if [ "$#" -eq 1 ]; then
  ml_input="$(source_for_repl "$1")"
else
  for ml in "$@"; do
    module_name="$(module_name_for_file "${ml}")"
    ml_input+="let __module = \"${module_name}\""$'\n'
    ml_input+="$(source_for_repl "${ml}")"$'\n'
  done
fi
ml_input="${ml_input//\\/\\\\}"
uart_input="${ml_input}"$'\x04'

raw="$("${cor24_run}" \
  --load-binary "${build_dir}/pvm.bin@0" \
  --load-binary "${build_dir}/ocaml.p24m@0x040000" \
  --load-binary "${input_image}@0x080000" \
  --patch "0x${code_ptr}=0x040000" \
  --patch "0x${heap_limit}=0x03F000" \
  --entry 0 -u "${uart_input}" --speed 0 -n 3000000000 -t "${cor24_wall_seconds}" 2>&1 | \
  awk '
    /^UART output:/ { in_out = 1; sub(/^UART output: /, ""); }
    /^Executed / { in_out = 0 }
    in_out { print }
  ' | tr -d '\r' | sed '1s/^PVM OK$//; /^$/d; /^HALT$/d')"

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
my @by_len = sort { length($b) <=> length($a) } @src_lines;
my $out = "";
for my $line (split /\n/, $raw, -1) {
    if ($line =~ /^let __module = "[^"]*"$/) { next; }
    if ($line =~ /^> /) {
        my $rest = substr($line, 2);
        my $stripped = 1;
        while ($stripped && $rest ne "") {
            $stripped = 0;
            $rest =~ s/^\s+//;
            for my $src (@by_len) {
                if (length($rest) >= length($src) && substr($rest, 0, length($src)) eq $src) {
                    $rest = substr($rest, length($src));
                    $stripped = 1;
                    last;
                }
            }
        }
        $rest =~ s/^\s+//;
        next if $rest =~ /^let __module = "[^"]*"$/;
        $out .= $rest . "\n" if $rest ne "";
    } else {
        $out .= $line . "\n";
    }
}
$out =~ s/\n+$/\n/;
print $out;
' "$@")"

printf '%s\n' "${clean}"
