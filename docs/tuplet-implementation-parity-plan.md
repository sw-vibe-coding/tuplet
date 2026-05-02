# Tuplet Implementation Parity Plan

This plan aligns four related implementations so demos and language
ideas can be compared consistently:

- `sw-embed/forthlet` -- Forth-hosted idea and demo prototype.
- `sw-vibe-coding/tuplet` -- this repo: OCaml-hosted compiler path
  targeting COR24 Forth.
- `sw-vibe-coding/tuplet-rs` -- Rust compiler/interpreter path.
- `sw-vibe-coding/DiscoveryOne` -- Rust/WebAssembly/3D superset.

The goal is not identical internals. The goal is demo parity: each
language idea has a documented source example, a known support level in
each implementation, and a clear path from parsed fixture to executable
demo.

## Current Snapshot

| Implementation | Current strongest area | Gap relative to demo parity |
|---|---|---|
| `forthlet` | Richest idea catalog and Forth demo traces. | Not the main OCaml-to-Forth compiler path; examples need translating to `.tup` forms. |
| `tuplet` | Lexer, dynamic literal registry, parser, real-source memory handoff, syntax matching, tuple signature and tuple assignment parsing. | No checker, IR, interpreter, Forth emitter, prelude, or executable demos yet. |
| `tuplet-rs` | Conventional compiler pipeline: parser, checker, IR, early evaluator fixtures. | No Forth target; README/status should be treated as possibly stale versus commits and fixture corpus. |
| `DiscoveryOne` | Superset demos: Power, facets, minted syntax, WASM, web UI, library grid, pipeline, aspects, 3D viewer. | Many features are beyond Tuplet's near-term 2D/COR24 scope and should be treated as future inspiration, not immediate parity requirements. |

## Parity Tracking Model

Each idea should move through the same ladder:

1. **Documented** -- source sketch and semantics are written down.
2. **Parsed** -- deterministic AST or parse dump exists.
3. **Checked** -- name, arity, and shape rules are enforced.
4. **Lowered** -- deterministic IR dump exists.
5. **Executed** -- interpreter or runtime output exists.
6. **Demoed** -- named example with a user-facing walkthrough exists.

No idea should be called demo-ready in this repo until it reaches
`Demoed`. Parser-only fixtures are still useful, but they should be
labeled honestly.

## Initial Feature Matrix

| Idea | Source repo with strongest example | Tuplet status now | Target parity level |
|---|---|---|---|
| Mint operator and arrows | all | Lexed and parsed | Demoed |
| Dynamic `*syntax` declarations | `DiscoveryOne`, `tuplet`, `tuplet-rs` | Parsed from real source | Demoed |
| `do _ while _ end` | `DiscoveryOne` | Parsed and syntax-matched | Demoed |
| `unless _ do _ end` | `DiscoveryOne` | Not covered | Parsed first, later demoed |
| Tuple variable signature `*coord2 -> (x y)` | `forthlet`, `tuplet-rs` | Parsed from real source | Executed |
| Tuple assignment/destructuring `a, b <- coord2` | `forthlet`, `tuplet-rs` | Parsed from real source | Executed |
| Typed scalar variables | `forthlet`, `DiscoveryOne` | Not implemented | Checked |
| Tuple-valued operators `max2`, `min2`, `div2` | `forthlet` | Not implemented | Executed |
| Call-site tuple splicing `plot(coord2 Red 50%)` | `forthlet` | Not implemented | Checked first |
| Flow notation / pipes | `forthlet` | Not implemented | Parsed first |
| Approximate predicates | `forthlet` | Not implemented | Parsed first |
| Power demo | `forthlet`, `tuplet-rs`, `DiscoveryOne` | Not executable | Demoed |
| Facets, aspects, 3D viewer | `DiscoveryOne` | Out of near-term Tuplet scope | Documented only |

## Phase 0: Parity Inventory

Create a durable inventory before more implementation work.

Deliverables:

- Add `docs/demo-parity.md` or extend this document with a full table
  of demos and support level per repo.
- Link each row to concrete files in sibling repos:
  `forthlet/examples`, `forthlet/fixtures`, `tuplet-rs` fixtures, and
  `DiscoveryOne/examples` plus `work/reg-rs`.
- Add a small `demos/README.md` in this repo explaining the ladder:
  documented, parsed, checked, lowered, executed, demoed.

Exit criteria:

- Every currently known idea has an owner row.
- No row is ambiguous about whether it is parsed-only or executable.

## Phase 1: Parser Parity

Finish parser coverage for the ideas that can be represented without
checker or runtime semantics.

Priority fixtures:

- `unless _ do _ end` syntax declaration and use site.
- Multi-output verb signature shape, such as `*max2 (a b) -> (q r)`.
- Tuple literal and tuple expression groups.
- Call forms with zero, one, and many arguments.
- Named tuple fields if still wanted before checker.
- Negative parser fixtures for unsupported or malformed templates.

Deliverables:

- `tests/parser/*.input` real-source fixtures where possible.
- `work/reg-rs/tuplet_parse_memory_*` baselines.
- Parser docs updated with supported AST shapes and known scaffolding.

Exit criteria:

- Parser saga can be closed or explicitly reduced to a known cleanup
  list.
- Checker entrance criteria are met with no hidden parser blockers.

## Phase 2: Checker Parity

Bring this repo up to the support level needed for tuple and syntax
demo validation.

Priority rules:

- Name resolution for scalar variables, tuple variables, and minted
  signatures.
- Tuple arity from suffixes and signature output groups.
- Assignment arity: LHS pattern size must match RHS output arity.
- Registered syntax slot arity: each captured slot must have a known
  output shape.
- Stable diagnostics for unbound names and arity mismatches.

Reference fixtures:

- `forthlet/fixtures/check-tuple-arity-*.fth`.
- `tuplet-rs` `check_pass_*` and `check_fail_*` fixtures.
- `DiscoveryOne` `d1_check_*` baselines for diagnostic shape.

Deliverables:

- `src/checker.ml`.
- Typed/checker dump format.
- `work/reg-rs/tuplet_check_*` pass and fail baselines.

Exit criteria:

- `coord2`, tuple destructuring, and basic syntax applications are
  checked deterministically.

## Phase 3: IR Parity

Lower checked AST into a small stack IR suitable for both reference
interpretation and Forth emission.

Priority IR forms:

- Push integer, load/store scalar, load/store tuple field.
- Call builtin or registered verb.
- Syntax expansion with slot splicing.
- `IPrimForth "WORD"` escape for the Forth backend.
- Sequence/block forms needed for `do..while`.

Reference fixtures:

- `tuplet-rs` `ir_*` fixtures.
- `DiscoveryOne` `d1_ir_power_dump`.
- `docs/lowering.md` in this repo.

Deliverables:

- `src/ir.ml`, `src/lower.ml`.
- `work/reg-rs/tuplet_ir_*` baselines.

Exit criteria:

- `coord2`, tuple assignment, and `do..while` produce stable IR dumps.

## Phase 4: Execution Parity

Add a reference execution path before depending fully on Forth output.

Options:

- Minimal OCaml-subset interpreter over the IR, as planned in
  `docs/plan.md`.
- Or a narrower test oracle for the first executable demos, if the
  OCaml host cost is too high.

Priority demos:

- Scalar mint and assignment.
- Tuple destructuring.
- `max2` or `div2`.
- `do..while` counter demo.

Deliverables:

- `src/interp.ml` or equivalent oracle.
- `work/reg-rs/tuplet_interp_*` baselines.

Exit criteria:

- Interpreter output matches intended Forth output for the first demo
  set.

## Phase 5: Forth Emitter Parity

Make this repo's unique path visible: Tuplet source compiled through
OCaml-hosted compiler code to COR24 Forth.

Priority output:

- Variables and tuple storage.
- Primitive Forth escapes.
- Registered syntax expansion for `do..while`.
- Generated `.fs` files under a gitignored work directory.
- `cor24-run` baselines using existing Forth smoke patterns.

Deliverables:

- `src/emit.ml`.
- CLI or script entrypoints for `tuplet compile` and `tuplet run`.
- `work/reg-rs/tuplet_run_*` baselines.

Exit criteria:

- The `do..while` PoC runs under COR24 Forth and prints the expected
  output.

## Phase 6: Demo Catalog

Create a user-facing set of demos with honest implementation status.

Initial demo set:

- `demos/dowhile.tup`
- `demos/unless.tup`
- `demos/coord2.tup`
- `demos/div2.tup`
- `demos/max2-min2.tup`
- `demos/power.tup`
- `demos/plot-splicing.tup`
- `demos/approx-predicate.tup`

Each demo should include:

- Source file.
- Support level badge in `demos/README.md`.
- Regression baseline for the highest currently supported level.
- Notes on which sibling repo has the strongest current equivalent.

Exit criteria:

- A reader can run one command to see all demos at their current
  support level.
- Demo parity gaps are visible without reading four repositories.

## Phase 7: Superset Alignment

Only after the 2D/COR24 path is healthy, selectively pull lessons from
DiscoveryOne.

Candidates:

- Library grid metadata as a textual `tuplet list` or `tuplet docs`
  command.
- Aspect-like trace/profile annotations as documented future syntax.
- Pipeline examples as later demos, not core compiler blockers.
- 3D/facet material as cross-project documentation, not immediate
  implementation scope.

Exit criteria:

- Tuplet's docs clearly explain which DiscoveryOne ideas are inherited,
  which are deferred, and which are intentionally out of scope.

## Immediate Next Steps

1. Complete the parser saga exit audit.
2. Add the parity inventory table and links to concrete sibling files.
3. Start `tuplet-checker` with tuple arity and unbound-name fixtures.
4. Promote `coord2` from parsed to checked.
5. Promote `do..while` from parsed to checked, then lowered.
