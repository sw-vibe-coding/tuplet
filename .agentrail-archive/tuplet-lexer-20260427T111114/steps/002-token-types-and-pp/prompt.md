# Step: token-types-and-pp

Define the token algebraic data type covering everything in
`docs/grammar.md`, plus a deterministic pretty-printer
(`dump_tokens`) that produces a one-token-per-line format for
reg-rs baselines. Add a small in-source test fixture that builds
a hand-written token list and verifies the dump string. **No
lexing logic yet** -- this step is data-shape + serialization
only.

## Scope

- `src/token.ml` defining the token type. Cover, at minimum:
  - `TIdent of string`
  - `TInt of int`
  - `TPct of int`           (* 0..100 *)
  - `TLArrow`               (* `<-` *)
  - `TRArrow`               (* `->` *)
  - `TLParen` / `TRParen`
  - `TLBrace` / `TRBrace`   (* `{` `}` for anonymous-verb literals *)
  - `TComma`
  - `TUnderscore`           (* template slot marker *)
  - `THash of string`       (* `# <comment text>` -- carry the text for round-trip *)
  - `TLiteral of string`    (* dynamically registered literal -- e.g. `if`, `then` *)
  - `TEOF`
- `src/token_dump.ml` (or merged into token.ml) with
  `dump_tokens : token list -> string` returning a multi-line
  string, one token per line, deterministic format. Suggested
  format:
  ```
  IDENT  <name>
  INT    <int>
  PCT    <int>
  LARROW
  RARROW
  LPAREN
  RPAREN
  LBRACE
  RBRACE
  COMMA
  USCORE
  HASH   <text>
  LIT    <name>
  EOF
  ```
- `src/token_test.ml` with a top-level expression that builds a
  small representative token list and prints the result of
  `dump_tokens` on it. Document in a comment what the expected
  output is. Run via `scripts/run-ml.sh src/token_test.ml`.
- A reg-rs baseline `tuplet_token_types_dump` that runs the test
  and captures the exact dump string. Run twice, confirm stable.

## Source-host constraints

`sw-cor24-ocaml` is an integer-subset OCaml interpreter.
Confirmed limits so far: top-level expressions only (no
`let () = ...`). Other limits will surface here:

- Whether **user-defined sum types** (`type token = ...`) are
  supported needs verification. The README does not document
  variants.
- If unsupported, fall back to the tagged-tuple encoding
  documented in `docs/design.md`'s "OCaml-subset compatibility"
  subsection: each token becomes `("IDENT", "name")` or similar,
  and `dump_tokens` pattern-matches on the first slot.

If user-defined sum types fail to parse:

1. Confirm the failure with a minimal repro (a 2-line `.ml` file
   defining `type t = A | B` and matching on it).
2. File `gh issue create --repo sw-embed/sw-cor24-ocaml` with
   the repro and request user-defined variants.
3. Continue this step using the tagged-tuple fallback (it is
   documented and supported by the existing OCaml subset).
4. Note the issue number in `docs/lexer.md` under a new
   "Upstream limitations" section.

## Style

- Files under `src/` follow the OCaml-subset constraint: top-
  level expressions for any side-effecting test code; functions
  via `let rec ... in ...` or top-level `let f = ...` if
  supported.
- ASCII-only source.
- Document in `docs/lexer.md` the chosen representation
  (variants vs tagged tuples) and the dump format.

## Do

1. Probe variant support: write
   `src/probes/variant_probe.ml` with `type t = A | B let _ =
   match A with A -> print_endline "A" | B -> print_endline
   "B"`. Run via `scripts/run-ml.sh`. Record the outcome in
   `docs/lexer.md` under "OCaml-subset notes".
2. Pick the representation based on probe outcome.
3. Implement `src/token.ml` and `dump_tokens`.
4. Implement `src/token_test.ml` building a list like
   `[ TIdent "coord2"; TLArrow; TInt 3; TComma; TInt 9; TEOF ]`
   and printing the dump.
5. Run via `scripts/run-ml.sh`. Confirm output is deterministic
   (run twice).
6. Register reg-rs baseline `tuplet_token_types_dump`. Run
   twice.
7. Update `docs/lexer.md` with the chosen representation and
   dump format spec.

## If blocked

- If neither variants nor pairs of strings work, file an issue
  and `agentrail abort`. (Strings + pairs are documented as
  working in `sw-cor24-ocaml`; this is not the expected path.)
- If `dump_tokens` produces nondeterministic output between
  runs (unlikely, but possible if the host has any nondeterminism
  in its hash table or string-pool ordering), document and file
  an issue.

## Do not

- Do not write any lexing function. No character-by-character
  scanning. No source-text-to-tokens path. That's a later step.
- Do not edit outside this repo.

## Finish

- Stage src/, docs/lexer.md, work/reg-rs/, and the full
  `.agentrail/` delta.
- Commit with a message like `feat(lexer): token type +
  dump_tokens with reg-rs baseline`.
- Push.
- `agentrail complete --summary "token type + deterministic
  dump_tokens; baseline tuplet_token_types_dump green" --reward
  1 --actions "probed variant support; defined Token; wrote
  dump_tokens" --next-slug lex-trivia-comments --next-prompt
  <prompt-for-next-step>`.

## Suggested next step

`lex-trivia-comments` -- the first actual lexing function.
Inputs: a string of `.tup` source. Outputs: a token list where
the only meaningful tokens are `THash` for line comments;
whitespace is consumed silently. Add reg-rs fixtures: an empty
file, a file of only whitespace, a file with one comment, a
file with mixed whitespace and comments. The function signature
becomes the foundation every later lex step extends.
