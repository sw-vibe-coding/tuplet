# Saga: tuplet-lexer

## Goal

Build a hand-written lexer for `.tup` source. Implementation
language: the OCaml subset hosted by `sw-cor24-ocaml` (ints,
bools, strings, lists, pairs, options, pattern matching,
`let rec`, `read_line`, qualified names). The lexer must support
**dynamic registration of new literal tokens** so the parser can
extend the keyword set as it processes `syntax` declarations
(per `docs/kernel.md`).

## Source of truth

- `docs/grammar.md` -- lexical rules and Unicode alias table.
- `docs/kernel.md` -- the parser/lexer extension contract;
  literal tokens registered at runtime.
- `docs/plan.md` -- saga 1 entrance/exit criteria.

## In scope

- Tokenizing every form documented in `docs/grammar.md`:
  identifiers (including arity-suffix digits and trailing `?`),
  integer literals, percent literals, comma, parens, `<-`,
  `->`, `_` (template slot), `{` `}` (anonymous-verb literal),
  `#` line comments, the symbolic `+ - *` operators, named
  operators (`max`, `min`, `div`, `max2`, `min2`, `div2`).
- Folding the Unicode aliases from `docs/grammar.md`'s table to
  their ASCII canonical forms before the parser sees them.
- A `Lexer.add_literal` (or equivalent) hook that the parser
  can call to register a new literal token; subsequent re-lexing
  of source treats that string as a literal token, not as an
  identifier.
- A `tuplet lex <file>` CLI mode (or test-only equivalent) that
  emits a deterministic token-per-line dump for reg-rs baselines.
- reg-rs baselines under `work/reg-rs/tuplet_lex_*` for each
  meaningful lexer scenario.

## Out of scope

- Parsing, AST, IR, semantics. Token stream only.
- Full UTF-8 codec; the alias table is small and ASCII-canonical
  post-fold, so byte-pattern matching suffices.
- Performance tuning. Correctness first.
- Generated Forth output.

## Hard rules

- **Do not edit outside this repo.**
- Missing OCaml-subset features in `sw-cor24-ocaml` are GitHub
  issues (`gh issue create --repo sw-embed/sw-cor24-ocaml`),
  never local workarounds. If a step is blocked, file the issue
  and `agentrail abort --reason "blocked on
  sw-embed/sw-cor24-ocaml#<n>"`.
- Push every commit in the same session.
- Stage the full `.agentrail/` delta with each step's commit
  (per `CLAUDE.md` section 4).
- `markdown-checker` clean on every changed `.md`.
- reg-rs: track `*.rgt` and `*.out`; ignore `*.tdb` and `*.lock`
  (already in `.gitignore`).
- Every new lexer scenario gets a reg-rs baseline before the
  step closes.

## Phased breakdown

Phase 1.0 -- build skeleton and the token data type.
Phase 1.1 -- trivia and comments.
Phase 1.2 -- numeric literals (int, percent).
Phase 1.3 -- identifiers (ASCII, arity suffix, trailing `?`).
Phase 1.4 -- punctuation and ASCII operators.
Phase 1.5 -- Unicode alias folding.
Phase 1.6 -- dynamic literal registry + parser callback contract.
Phase 1.7 -- CLI / test-driver wiring; reg-rs baselines.

Each phase becomes one or more steps; the phases above are the
intended grain, not a binding step list.

## End state

- `src/` contains the lexer source, runnable via
  `bash ~/github/sw-embed/sw-cor24-ocaml/scripts/run-ocaml.sh
  src/lex_main.ml` (or a wrapping script in this repo).
- `tests/lexer/` contains representative `.tup` inputs and
  `.expected.tokens` files.
- `work/reg-rs/tuplet_lex_*` baselines pass.
- The `Lexer.add_literal` contract is documented in a short
  `docs/lexer.md` (or appended to `docs/design.md`) so the
  parser saga can rely on it.
- `docs/plan.md` saga-index status flips `tuplet-lexer` from
  `upcoming` to `done`.
