# Step: lex-trivia-comments

The first actual lexing function. Inputs: a string of `.tup`
source. Outputs: a token list where the only meaningful tokens
are `THash` (kind 11) for line comments; whitespace is consumed
silently; `TEOF` (kind 13) terminates.

This step does **not** lex identifiers, numbers, punctuation, or
arrows yet -- those are subsequent steps. Goal here is the
function signature shape that every later lex step extends, plus
the harness for golden-input tests.

## Constraints learned in step 002

Read `docs/lexer.md` for the full list before starting. Key
points that shape this step's code:

- Every source file under `src/` is **one giant single-line
  expression** with nested `let rec ... in ...`. No top-level
  bindings.
- Tokens are `(kind_int, (int_payload, str_payload))` nested
  pairs.
- Only pairs (no 3-tuples), no `\n` escapes in string literals,
  no user variants.
- Reuse the exact dump shape from `src/token_test.ml`.

## Scope

- `src/lex_trivia.ml` -- a one-line program that:
  1. Defines a recursive `lex_one` taking a string and a
     position index, returning a token plus the new position.
     For this step, `lex_one` only handles: whitespace
     (consume), `#` line comments (emit THash), and end-of-
     input (emit TEOF).
  2. Defines `lex_all` that loops until TEOF, building a token
     list.
  3. Reads input from a hard-coded string literal (no
     `read_line` yet) -- the test fixture is baked in.
  4. Calls `lex_all` and dumps each token via the same
     `dump_tok` shape from `src/token_test.ml` (re-defined
     inline; sharing isn't possible per
     `sw-embed/sw-cor24-ocaml#3`).
- The fixture string contains: leading whitespace, two `# ...`
  line comments separated by a tab and spaces, trailing
  whitespace. Choose values that exercise every code path in
  `lex_one`.
- Reg-rs baselines:
  - `tuplet_lex_trivia_empty` -- empty input, expects only
    `EOF`.
  - `tuplet_lex_trivia_ws` -- input is only whitespace, expects
    only `EOF`.
  - `tuplet_lex_trivia_one_comment` -- one comment, expects
    `HASH <text>` then `EOF`.
  - `tuplet_lex_trivia_mixed` -- mixed whitespace and
    comments, expects each `HASH` in source order then `EOF`.

  Each baseline runs a separate `.ml` file with a different
  hard-coded fixture string. Once a future step adds
  `read_line`-driven lexing, the fixtures collapse into
  `tests/lexer/*.tup` files. For now, baked-in is acceptable.

## String inspection in the OCaml subset

The host's documented string operations are limited. Verify what
works by adding probes under `src/probes/`:

- `String.length s` -- check if available.
- Indexing: `String.get s i` or `s.[i]`.
- Substring: `String.sub s i n`.
- Comparison: `s = "#"` or per-char equality after indexing.

If any required operation is missing, **file a sw-cor24-ocaml
issue and `agentrail abort`**. Document workarounds attempted in
`docs/lexer.md` under OCaml-subset notes. Do not invent
character-by-character workarounds in pure OCaml when a stdlib
primitive ought to exist.

## Style and constraints

- ASCII-only sources.
- `markdown-checker` clean on every changed `.md`.
- Update `docs/lexer.md` "Implementation pattern" section if a
  new pattern emerges (e.g. how to thread the `pos` integer
  through the recursive lex calls).

## Do

1. Probe string ops first (length, index, substring, equality).
   Record results in `docs/lexer.md`.
2. Write `src/lex_trivia.ml` (and `src/lex_trivia_*.ml` per
   fixture) using the shape above.
3. Run each manually; verify the dump matches expectations.
4. Register reg-rs baselines for each. Run twice; confirm
   stable.
5. Update `docs/lexer.md` with anything learned.

## Do not

- Do not lex identifiers, numbers, or punctuation here.
- Do not implement `read_line`-driven input. The lexer reads
  from a hard-coded string for now; switching to `read_line`
  belongs in a later step.
- Do not edit outside this repo.

## If blocked

- Missing string-stdlib primitive (e.g., no `String.get`):
  file `gh issue create --repo sw-embed/sw-cor24-ocaml`,
  document, `agentrail abort`.
- Probe results contradict the documented OCaml subset (e.g.,
  README claims feature X works but probe shows it doesn't):
  file an issue clarifying.

## Finish

- Stage src/, docs/lexer.md, work/reg-rs/, full .agentrail/
  delta.
- Commit. Push.
- `agentrail complete --summary "lex_one + lex_all stub
  handling whitespace, #-comments, EOF; four reg-rs baselines"
  --reward 1 --actions "string-op probe; recursive lex shape
  threading position; per-fixture .ml file" --next-slug
  lex-numeric-literals --next-prompt <prompt-for-next-step>`.

## Suggested next step

`lex-numeric-literals` -- extend `lex_one` to recognize integer
literals (including leading `-`) and percent literals (digit run
followed by `%`). Reg-rs baselines per fixture. Carry forward
the per-fixture-file pattern unless the host gains string
parameterization.
