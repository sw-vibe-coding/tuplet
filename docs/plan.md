# Tuplet -- Phased Plan

> **Architecture source of truth:** `docs/kernel.md`. The
> kernel/prelude split decided there shapes every saga below.
> If this plan disagrees with `docs/kernel.md`, the kernel doc
> wins; raise the disagreement and update this file.

## Arc summary

`tuplet-scaffold` (Phase 0, in-progress) lays down the docs and
toolchain wiring. From there, eight follow-up sagas build the
PoC end-to-end: lexer -> registry-based parser -> registry-based
checker -> stack IR -> reference interpreter -> Forth emitter ->
**`lib/std.tup` prelude** -> demos. The seventh saga
(`tuplet-prelude`) is what makes Tuplet "mostly written in
itself"; the eighth proves it by running demos that depend on
the prelude.

## Saga index

| #  | Saga                          | Phase | One-line goal                                                                | Status        |
|----|-------------------------------|-------|------------------------------------------------------------------------------|---------------|
| 0  | `tuplet-scaffold`             | 0     | Docs (PRD, grammar, design, lowering, kernel) + toolchain smoke baselines.   | in-progress   |
| 1  | `tuplet-lexer`                | 1     | Tokenize `.tup`; surface registry-callback for template literals.            | upcoming      |
| 2  | `tuplet-parser`               | 2     | `syntax` registry + longest-match template matcher producing AST.            | upcoming      |
| 3  | `tuplet-checker`              | 3     | Name resolution + arity check against the registry; no hardcoded ops.        | upcoming      |
| 4  | `tuplet-ir`                   | 4     | AST -> stack IR including `IPrimForth` and anonymous-verb thunks.            | upcoming      |
| 5  | `tuplet-interp`               | 5     | Minimal reference interpreter over IR; oracle for emitter cross-checks.      | upcoming      |
| 6  | `tuplet-forth-emit`           | 6     | IR -> Forth into `work/generated/*.fs`; cor24-run round-trip via reg-rs.     | upcoming      |
| 7  | **`tuplet-prelude`**          | 7     | Write `lib/std.tup`: operators + control flow + tuple helpers in Tuplet.     | upcoming      |
| 8  | `tuplet-demos`                | 8     | Example gallery using prelude features only; "remove std.tup -> fail" test.  | upcoming      |

## Cross-cutting concerns

Every saga must honor these. They are not restated in each saga
section.

- **Do not edit outside this repo.** Tuplet code, docs, tests,
  generated Forth, and reg-rs baselines all live in
  `~/github/sw-vibe-coding/tuplet`.
- **Upstream gaps are GitHub issues, not local workarounds.**
  Missing features or bugs in `sw-embed/sw-cor24-ocaml` or
  `sw-embed/sw-cor24-forth` are filed via `gh issue create
  --repo sw-embed/<repo>`. Record the issue number under the
  saga's risks. If it blocks the saga, run `agentrail abort
  --reason "blocked on sw-embed/<repo>#<n>"`.
- **Push every commit in the same session.** Per CLAUDE.md
  section 4. Never defer `git push`.
- **Commit the full `.agentrail/` delta with each step.** Stage
  everything modified or new under `.agentrail/`, not just the
  step you thought you were touching.
- **`markdown-checker` clean on every changed `.md`.**
- **reg-rs baseline policy.** `*.rgt` (test definition) and
  `*.out` (golden output) are tracked; `*.tdb` and `*.lock` are
  ignored. New tests live under `work/reg-rs/` via
  `REG_RS_DATA_DIR=work/reg-rs reg-rs create ...`.

## Per-saga sections

### 1. `tuplet-lexer`

**Goal.** Tokenize Tuplet source. Hand-written lexer in the
OCaml subset hosted on `sw-cor24-ocaml`. Surfaces an interface
the parser uses to register new literal tokens during parsing
(needed because `syntax` declarations introduce new keywords).

**Entrance criteria.**
- `tuplet-scaffold` complete on `main`.
- `docs/grammar.md`, `docs/kernel.md` present.
- `tuplet_ocaml_smoke` reg-rs test green.

**Exit criteria.**
- `src/lexer.ml` (or equivalent path) tokenizes a `.tup` file
  to a list of tokens, dumpable as a deterministic line per
  token.
- ASCII and Unicode aliases per `docs/grammar.md` table both
  produce the same token stream.
- Registry-callback hook present: parser can call
  `Lexer.add_literal "if"` and a subsequent re-lex of the same
  source treats `if` as a literal token.
- Reg-rs baselines for: scalar literals, tuple-var names with
  arity suffixes, comments, ASCII vs Unicode form, dynamic
  registration round-trip.

**Key deliverables.**
- `src/lexer.ml`, `src/token.ml`.
- `tests/lexer/*.tup` + `*.expected.tokens`.
- `work/reg-rs/tuplet_lex_*.rgt` + `*.out`.

**Primary risks.**
- OCaml subset may lack efficient string compare or mutable
  hashtables for the literal registry. File upstream issue
  against `sw-embed/sw-cor24-ocaml` if so; fall back to assoc
  lists in the meantime.
- Unicode multi-byte handling. Strategy: keep alias folding
  byte-pattern based, narrow set, ASCII-canonical post-fold.

### 2. `tuplet-parser`

**Goal.** Build AST per `docs/design.md`, with a `syntax`
registry and longest-match template matcher. The parser knows
no operators or control-flow keywords -- those come from the
registry.

**Entrance criteria.**
- `tuplet-lexer` complete; lexer can register literal tokens.
- `docs/kernel.md` `syntax` semantics accepted.

**Exit criteria.**
- `src/parser.ml` parses kernel forms (`syntax`, `:`, `<-`,
  comma, parens, `#`, `_`, `{}`, `prim/forth`) without any
  registry entries.
- After processing one `syntax` declaration, subsequent code
  that matches the template parses to the documented AST.
- Longest-match-wins, first-declared-wins-on-ties: tested with
  a fixture that registers two overlapping templates.
- AST-dump format is deterministic (s-expr or similar).
- Reg-rs baselines for: kernel-only programs, template
  expansion sanity, ambiguity resolution, error messages on
  unknown tokens / unmatched templates.

**Key deliverables.**
- `src/parser.ml`, `src/ast.ml`, `src/registry.ml`.
- `tests/parser/*.tup` + `*.expected.ast`.

**Primary risks.**
- Template matching in the OCaml subset may need data
  structures (priority queue / trie) absent from the host. Plan
  for assoc-list fallback; profile only if needed.
- Registry mutation during parse complicates error recovery.
  Keep parser single-pass; on error, abort and report.

### 3. `tuplet-checker`

**Goal.** Name resolution and arity checking on the registry-based
AST. No hardcoded operators; every check goes through the
registry.

**Entrance criteria.**
- `tuplet-parser` complete; AST + registry stable.

**Exit criteria.**
- All Arity rules from `docs/grammar.md` enforced for forms
  defined in the kernel + any registered `syntax` declarations.
- Pass-case fixtures produce a typed-AST dump; fail-case
  fixtures produce the documented error message text.
- Reg-rs baselines for both pass and fail cases.

**Key deliverables.**
- `src/checker.ml`.
- `tests/checker/pass/*.tup`, `tests/checker/fail/*.tup` +
  `*.expected.err`.

**Primary risks.**
- Slot-arity propagation through nested templates; document
  the algorithm in a short note alongside the implementation.

### 4. `tuplet-ir`

**Goal.** Lower checked AST to the stack IR from
`docs/design.md`, extended with `IPrimForth` and anonymous-verb
thunks per `docs/kernel.md`.

**Entrance criteria.**
- `tuplet-checker` complete.

**Exit criteria.**
- Every IR opcode from the design doc emitted correctly,
  including `IPrimForth "WORD"` for raw escape and synthetic
  thunks for `{...}`.
- Reg-rs baselines for the IR dumps of representative programs
  (kernel-only, with prelude templates expanded).

**Key deliverables.**
- `src/ir.ml`, `src/lower.ml`.
- `tests/ir/*.tup` + `*.expected.ir`.

**Primary risks.**
- IR ergonomics for thunks; the synthetic-name strategy
  documented in `docs/kernel.md` (until
  `sw-embed/sw-cor24-forth#5` lands `:NONAME`) needs a stable
  naming scheme.

### 5. `tuplet-interp`

**Goal.** A minimal reference interpreter over the IR. Used as
an oracle for the Forth emitter -- not a target itself.

**Entrance criteria.**
- `tuplet-ir` complete.

**Exit criteria.**
- For every program in the test corpus, the interpreter
  produces the same output the Forth emitter will be expected
  to produce.
- Stub for `IPrimForth`: a small allowlist of supported words
  (`+`, `*`, `<`, `IF`, etc.) implemented in the interpreter
  with mock semantics.

**Key deliverables.**
- `src/interp.ml`.
- `tests/interp/*.tup` + `*.expected.out`.

**Primary risks.**
- Drift between interpreter and Forth semantics for edge
  cases; document divergences explicitly. The Forth output is
  authoritative; the interpreter is the cross-check.

### 6. `tuplet-forth-emit`

**Goal.** Emit Forth from IR per `docs/lowering.md`, into
`work/generated/<basename>.fs`. Concatenate kernel `forth.s` +
generated file, run under `cor24-run`, capture UART output via
reg-rs, compare against the interpreter.

**Entrance criteria.**
- `tuplet-ir` and `tuplet-interp` complete.
- `tuplet_forth_smoke` reg-rs test green.

**Exit criteria.**
- `tuplet compile <file>.tup` writes `work/generated/<file>.fs`.
- `tuplet run <file>.tup` runs end-to-end through `cor24-run`
  and prints the UART output section.
- For every program in the test corpus, interpreter output
  matches Forth output (modulo the documented divergence
  policy).
- Reg-rs baselines compare emitter output against the
  interpreter.

**Key deliverables.**
- `src/emit.ml`.
- `bin/tuplet` (the CLI).
- `work/generated/` (gitignored output dir).

**Primary risks.**
- Synthetic-name dictionary bloat from anonymous verbs; track
  count, file `sw-embed/sw-cor24-forth#5` followup if it bites.
- Per-instruction RX/TX trace lines from `cor24-run` shifting
  with emulator version; existing grep-preprocess pattern from
  `tuplet_forth_smoke` is the template.

### 7. `tuplet-prelude` (the bootstrap-proof saga)

**Goal.** Write `lib/std.tup`: every operator (`+ - * < = <> <=
>= not && ||`), every multi-output verb (`max min div max2 min2
div2`), and every control-flow construct (`if/then/else/end`,
`while/do/end`, sketch of `match`) defined in Tuplet using only
the kernel + earlier prelude entries + `prim/forth` escapes.

**Entrance criteria.**
- `tuplet-forth-emit` complete; round-trip via reg-rs working.

**Exit criteria.**
- `lib/std.tup` exists and loads without forward-reference
  errors.
- A test program using `+`, `if/then/else/end`, `while/do/end`
  produces the expected output via the Tuplet emitter, using
  *only* prelude features for those constructs.
- The prelude file has a header comment listing the load
  order; a build-time check fails on forward references.

**Key deliverables.**
- `lib/std.tup`.
- `tests/prelude/*.tup` exercising every prelude form.
- A loader / driver that wires `lib/std.tup` into the
  compiler's startup sequence.

**Primary risks.**
- The litmus test in `docs/kernel.md` is wrong somewhere. If a
  prelude entry needs a primitive that isn't in `prim/`, that's
  evidence the kernel inventory needs a new entry; revisit
  `docs/kernel.md` and document the change.
- Bootstrap order surprises (e.g., `&&` needs `if`, but `if`
  needs `0=` from `prim/`, etc.). Resolve by writing the load
  order BEFORE writing definitions.

### 8. `tuplet-demos`

**Goal.** Example gallery proving the language works in
practice. Six to ten `.tup` programs covering tuple decls,
destructuring, multi-output verbs, call-with-splice,
control-flow, and at least one program exercising the COR24
LED via a prelude-defined wrapper.

**Entrance criteria.**
- `tuplet-prelude` complete.

**Exit criteria.**
- 6-10 demos under `demos/*.tup`, each with a reg-rs baseline
  in `work/reg-rs/tuplet_demo_<name>.rgt` + `*.out`.
- Every demo runs via `tuplet run demos/<name>.tup` and
  produces stable UART output.
- A "negative" reg-rs test removes `lib/std.tup` and verifies
  representative demos *fail to parse* -- proving the prelude
  is load-bearing, not duplicated in the compiler.
- A README under `demos/` listing each demo with one-line
  description.

**Key deliverables.**
- `demos/coord2.tup` -- tuple init + destructure.
- `demos/divmod.tup` -- `div2` use.
- `demos/sort_pair.tup` -- `max2` / `min2`.
- `demos/branch.tup` -- prelude `if/then/else`.
- `demos/loop.tup` -- prelude `while`.
- `demos/plot.tup` -- call-with-splice into `plot`.
- `demos/led.tup` -- COR24 LED via a `set_led` wrapper from a
  prelude addendum.
- `demos/README.md` listing all of the above.

**Primary risks.**
- LED demo requires Forth runtime words for COR24 board I/O
  that may need confirmation in `sw-cor24-forth`; verify
  before committing to the demo.
- Demo audience drift -- keep them tight, focused on language
  features, not contrived puzzles.

## Out-of-scope (still)

Per `docs/prd.md` non-goals; not revisited in this plan:

- Hindley-Milner type inference; no static types beyond arity.
- Modules, functors, namespaces (the `prim/` and `std/`
  prefixes are *naming convention*, not a module system).
- Exceptions, effects.
- GC heap; values are stack cells.
- Floating point beyond percent literals.
- Self-hosting parser (parser stays in OCaml; revisit
  post-PoC).

## Future work (Phase 9+, not planned)

- `:NONAME` once `sw-embed/sw-cor24-forth#5` lands; remove
  synthetic-name fallback.
- Mixfix precedence levels (Agda-style) replacing
  longest-match.
- Hygienic macros.
- Self-hosting Tuplet parser written in Tuplet.
- Type system over arity.
