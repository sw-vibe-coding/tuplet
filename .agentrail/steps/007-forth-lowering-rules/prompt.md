# Step: forth-lowering-rules

Write `docs/lowering.md` -- the rule-by-rule mapping from Tuplet
stack IR (see `docs/design.md`) to Forth source that runs on
`sw-cor24-forth`. This is the spec the Forth emitter will follow.

## Required sections

1. **Runtime words the PoC assumes.** Enumerate exactly which Forth
   words the generated code uses, and for each note whether it is
   already provided by `sw-cor24-forth/forth.s`. The built-in word
   list in `sw-cor24-forth/README.md` is authoritative. Cover at
   least: `VARIABLE`, `!`, `@`, `:`, `;`, `EMIT`, `.`, `+`, `-`,
   `*`, `/` (or `DIV`), `MOD`, `DUP`, `DROP`, `SWAP`, `OVER`, `>R`,
   `R>`, `R@`, `0<` / `<`, `CR`, `SPACE`, `HERE`, `ALLOT`, and
   whatever is needed for a minimal `plot` builtin. If anything on
   that list is missing from the Forth kernel, flag it as a
   candidate upstream issue under an "Upstream dependencies"
   section and stop -- do not paper over gaps here.

2. **Lowering per IR instruction.** One row per `instr` from
   `docs/design.md`, showing the Forth it emits. Keep rows short:
   input stack, output stack, emitted Forth. Example for
   `ILoadTuple ("coord2", 2)` -> `coord2@`.

3. **Lowering per surface construct.** Specifically:
   - Tuple declaration `name -> (f1 ... fN)` emits `N`
     `VARIABLE <name>-<fi>` lines plus `: <name>!  ( ... -- )` and
     `: <name>@ ( -- ... )` words.
     Include the exact word body (reverse-order stores for `!`,
     forward-order fetches for `@`, matching the stack-top-last
     convention in `docs/design.md`).
   - Signature declaration `name(inputs) -> (outputs)`: emits
     nothing (signatures are compile-time only for the PoC); the
     verb body is provided elsewhere (builtin or runtime-linked).
   - Scalar assignment `x <- expr`: emits RHS then `x!`.
   - Destructuring assignment `a, b <- expr`: emits RHS (which
     leaves N values on the stack) then `b! a!` -- reverse order
     so each name pops its matching value.
   - Call with splice `f(args)`: emit each arg in source order,
     then `f` (a word that consumes all inputs and pushes the
     outputs). Splicing is automatic because a tuple var arg is
     just `coord2@`.
   - Binary op: `a OP b` emits the Forth for `a`, then for `b`,
     then the op word (e.g. `+`, `max`, `max2`).
4. **Builtin verb bodies.** For each builtin in the design's
   verb registry, show the Forth definition (or note "native
   primitive" if it is already a Forth word). Include `max`,
   `min`, `max2`, `min2`, `div2`, `plot`. A minimal `plot`
   body is acceptable: print the four inputs and push `-1`
   (Forth true).

5. **Worked example.** The same program used in `docs/design.md`
   lowered to Forth line-by-line, annotated with the originating
   IR instruction in a `\` comment. Run-through, not just the
   final listing.

6. **File layout convention.** Where generated Forth lives
   (`work/generated/*.fs` or similar) and how the test harness
   will invoke `cor24-run` on it -- just a sketch; the actual
   harness is a later step.

## Style

- ASCII-only (`markdown-checker -f docs/lowering.md`).
- Under ~300 lines.
- Fenced code blocks; short tables.

## Reference

- `docs/design.md` -- IR and AST.
- `docs/grammar.md` -- surface syntax.
- `~/github/sw-embed/sw-cor24-forth/README.md` -- authoritative
  builtin word list.
- `~/github/sw-embed/sw-cor24-forth/CLAUDE.md` -- register
  allocation and cor24-run invocation.

## If blocked

- If `sw-cor24-forth` lacks a word the lowering needs (e.g., no
  integer division, no `MOD`), **do not invent a workaround in
  this repo**: file `sw-embed/sw-cor24-forth` issue, record it in
  a "Blocked" section of `docs/lowering.md`, and run
  `agentrail abort --reason "blocked on sw-embed/sw-cor24-forth#<n>"`.

## Finish

- Commit code + full .agentrail/ delta + push.
- `agentrail complete --summary "drafted docs/lowering.md with
  Forth emission rules and worked example" --reward 1 --actions
  "matched IR to sw-cor24-forth builtins; documented tuple-var
  word pattern"`.

## Suggested next step

Propose `phased-plan`: write `docs/plan.md` that turns the Phase
0-8 arc (PRD, Scaffold saga plan) into a concrete list of
follow-up sagas with entrance/exit criteria for each. Include:
`tuplet-lexer`, `tuplet-parser`, `tuplet-checker`, `tuplet-ir`,
`tuplet-interp`, `tuplet-forth-emit`, `tuplet-demos`. Each future
saga gets one paragraph in `docs/plan.md`.
