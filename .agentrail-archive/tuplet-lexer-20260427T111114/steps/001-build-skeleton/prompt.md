# Step: build-skeleton

Lay down the minimum project skeleton needed to run an OCaml
program from this repo against the `sw-cor24-ocaml` interpreter.
This step does **not** write any lexer code yet. Goal is to make
"edit a `.ml` file in `src/`, run it, see a known output, capture
the result via reg-rs" a one-line operation that future steps can
rely on.

## Scope

- `src/` directory created with an exemplar entry-point file.
- A wrapping shell script `scripts/run-ml.sh` that locates and
  invokes `~/github/sw-embed/sw-cor24-ocaml/scripts/run-ocaml.sh`
  on a `.ml` source path, suppressing the source-echo prefix
  printed by the Pascal runtime so downstream test baselines see
  only program output.
- A reg-rs baseline `tuplet_build_skeleton` that runs the
  exemplar via the script and verifies the cleaned output.
- A short `docs/lexer.md` stub (3-5 lines) saying "lexer
  implementation lives under `src/`; build via
  `scripts/run-ml.sh`". Detail will be added in later steps.

## Do

1. Create `src/lex_main.ml` containing exactly:
   ```
   let () = print_endline "tuplet-lexer skeleton"
   ```
   (Use OCaml's standard `print_endline`; the
   `sw-cor24-ocaml` interpreter supports it -- verified by its
   `read_line` echo demo in
   `~/github/sw-embed/sw-cor24-ocaml/docs/stdin-and-getc.md`.)

2. Create `scripts/run-ml.sh` (chmod +x) that:
   - Takes one argument: a path to a `.ml` file.
   - Invokes
     `bash ~/github/sw-embed/sw-cor24-ocaml/scripts/run-ocaml.sh
     "$1"`.
   - Pipes stdout through a small filter that removes the
     `> ...` source-echo prefix. The Pascal runtime echoes the
     last source line as `> <line>`. Trim only the leading `> `
     prefix and the echoed source content; preserve real program
     output. Simplest implementation: keep only lines that do not
     start with `> ` AND, on the line that includes both echo and
     the first program output, drop the echo by string-splitting.
     If a clean-cut filter is hard, an acceptable fallback is to
     emit the raw output verbatim and let the reg-rs preprocess
     handle the prefix; document whichever you choose.
   - Use `set -euo pipefail`. Quote variables.

3. Run `scripts/run-ml.sh src/lex_main.ml` once manually.
   Expected output: `tuplet-lexer skeleton`.

4. Register the reg-rs baseline:
   ```
   REG_RS_DATA_DIR=work/reg-rs reg-rs create \
     -t tuplet_build_skeleton --timeout 60 \
     -c 'bash /Users/mike/github/sw-vibe-coding/tuplet/scripts/run-ml.sh /Users/mike/github/sw-vibe-coding/tuplet/src/lex_main.ml' \
     --desc 'tuplet build skeleton -- prints "tuplet-lexer skeleton" via sw-cor24-ocaml'
   REG_RS_DATA_DIR=work/reg-rs reg-rs run -p tuplet_build_skeleton
   ```
   Run twice to confirm stability before moving on.

5. Write `docs/lexer.md`:
   ```
   # Tuplet Lexer

   Implementation lives under `src/`; build/run via
   `scripts/run-ml.sh <file.ml>`. Smoke baseline:
   `tuplet_build_skeleton`.

   Detailed design forthcoming -- see `docs/grammar.md` for
   what the lexer produces and `docs/kernel.md` for the
   dynamic-literal-registry contract.
   ```

## If blocked

- If `print_endline` is not actually supported, fall back to
  `print_int 42` and adjust the reg-rs baseline. If that also
  fails, file an issue at `sw-embed/sw-cor24-ocaml` describing
  the failure and `agentrail abort`.
- If the source-echo filter cannot reliably clean the output
  for any reason, document the issue, accept the raw-output
  baseline as-is for now, and proceed -- the cleaner is a
  nice-to-have, not a blocker.

## Do not

- Do not write any lexer logic in this step. Token types,
  identifier rules, comment handling, etc. are all later steps.
- Do not edit any file under
  `~/github/sw-embed/sw-cor24-ocaml/`.

## Finish

- Stage `src/lex_main.ml`, `scripts/run-ml.sh`, `docs/lexer.md`,
  `work/reg-rs/tuplet_build_skeleton.{rgt,out}`, and the full
  `.agentrail/` delta.
- Commit with a message like `chore: tuplet-lexer skeleton +
  reg-rs build smoke`.
- Push.
- `agentrail complete --summary "build skeleton: src/, run-ml.sh,
  baseline" --reward 1 --actions "set up entry-point .ml,
  wrapper script, and reg-rs baseline" --next-slug
  token-types-and-pp --next-prompt <prompt-for-next-step>`.

## Suggested next step

Propose `token-types-and-pp` -- define the token algebraic
type covering everything in `docs/grammar.md` (identifiers,
int-lit, pct-lit, punctuation, `<-`, `->`, `_`, `{`, `}`,
comment, EOF), plus a `dump_tokens : token list -> string`
that produces a deterministic one-token-per-line format. Add
unit-style tests as `.ml` files in `src/tests/` that build a
small token list and verify the dump string. Reg-rs baselines
per test.
