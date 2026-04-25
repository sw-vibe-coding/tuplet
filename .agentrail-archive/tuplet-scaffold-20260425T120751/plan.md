# Saga: tuplet-scaffold

## Goal

Bring up the Tuplet PoC language — an infix programming language with
first-class named tuple bundles (`coord2`), multi-output verbs (`max2`,
`div2`), destructuring assignment, and call-site argument splicing,
grounded in Forth-like stack semantics underneath — far enough that a
follow-up saga can begin implementing the lexer.

See `docs/research.txt` for the language motivation and sketches.
Tagline: "Tuplet: first-class value bundles in an infix language."

## Targets

- Parser host: `~/github/sw-embed/sw-cor24-ocaml` — an integer-subset
  OCaml interpreter (strings, lists, pairs, options, pattern matching)
  running on the COR24 P-code VM. The Tuplet parser will be written as
  an OCaml program that runs in this interpreter.
- Runtime / test environment: `~/github/sw-embed/sw-cor24-forth` — DTC
  Forth on COR24. Generated Tuplet code will be lowered to Forth words
  and executed here.
- Regression testing: `reg-rs` (golden-output tool) for both the parser
  and the Forth runtime.

## Phased arc (for orientation; only Phase 0 is in this saga)

- **Phase 0: project skeleton** — THIS saga
- Phase 1: lexer
- Phase 2: parser
- Phase 3: AST + pretty-printer
- Phase 4: symbol table + arity checker
- Phase 5: stack IR
- Phase 6: reference interpreter
- Phase 7: Forth code generator
- Phase 8: tests and demos

## This saga's scope (Phase 0)

1. Commit the existing seed docs and `.agentrail/` into git so the
   project has a clean tracked baseline.
2. Write a concise `docs/prd.md` for Tuplet distilled from
   `docs/research.txt`.
3. Fix an ASCII fallback surface grammar in `docs/grammar.md` (with
   Unicode aliases noted). Target extension: `.tup`.
4. Smoke-test the `sw-cor24-ocaml` toolchain: run a trivial `.ml`
   program and capture a `reg-rs` baseline that proves the parser host
   is wired up on this machine.
5. Smoke-test the `sw-cor24-forth` toolchain: run a trivial Forth
   program on `cor24-run` and capture a `reg-rs` baseline.
6. Sketch AST + stack IR in `docs/design.md`.
7. Document Forth lowering rules in `docs/lowering.md` — how tuple
   assignment, destructuring, calls-with-splicing lower to Forth words.
8. Write `docs/plan.md` with the phased plan above, split into
   follow-up sagas.

## Hard rules

- **Do not edit files outside this repo.** All Tuplet code, docs, and
  tests live in `~/github/sw-vibe-coding/tuplet`.
- **If `sw-cor24-ocaml` or `sw-cor24-forth` is missing a feature or has
  a bug**, file a GitHub issue against the upstream repo
  (`sw-embed/sw-cor24-ocaml` or `sw-embed/sw-cor24-forth`) via `gh
  issue create`, then mark the current step blocked with `agentrail
  abort --reason "blocked on <repo>#<issue>"`. Do not work around
  upstream bugs or missing features in this repo.
- Never use `.agentrail/` with anything other than `agentrail`
  subcommands.

## End state

- All seed + generated docs committed on `main`.
- `docs/prd.md`, `docs/grammar.md`, `docs/design.md`,
  `docs/lowering.md`, `docs/plan.md` all present and concise.
- `reg-rs` baselines for the OCaml and Forth hello-world smoke tests
  captured.
- The next saga (`tuplet-lexer`) can start from a clean, documented
  foundation.
