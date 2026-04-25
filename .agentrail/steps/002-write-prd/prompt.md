# Step: write-prd

Write `docs/prd.md` — a concise Product Requirements Document for the
Tuplet PoC language, distilled from `docs/research.txt`.

## Source material

- `docs/research.txt` — full design conversation and rationale.
  Especially the final sections (~line 2900+) covering the PoC scope,
  IR sketch, arity checking, Forth lowering, and the naming/branding
  summary.

## Required sections

1. **Overview** — one paragraph. Tuplet is an infix PoC language where
   expressions can emit multiple named values that flow into other
   expressions; stack semantics underneath.
2. **Goals** — bullet list. First-class tuple bundles, multi-output
   verbs, destructuring, call-site splicing, arity checking, Forth
   lowering.
3. **Non-goals (initial PoC)** — no type inference, no modules, no
   exceptions, no GC-managed heap, no floating point beyond
   percentages.
4. **Core concepts** — named tuple variable (`coord2`), verb
   signature with the mapping operator (`───‣` / `->`), multi-value
   assignment (`a, b <- coord2`), call-site splicing (`plot(coord2
   Red 50%)`).
5. **Surface syntax** — state that two surfaces exist: a Unicode form
   (from `research.txt`) and an ASCII fallback. Full grammar lives in
   `docs/grammar.md` (next step).
6. **Example programs** — include 4–6 from `research.txt`:
   tuple initialization, destructuring, `max2`, `div2`, `plot` with
   splice, a signature block.
7. **Implementation targets** — parser written in the OCaml subset
   supported by `sw-cor24-ocaml`; code generator emits Forth consumed
   by `sw-cor24-forth`; tests via `reg-rs`.
8. **Success criteria** — sample programs parse; arity errors caught;
   stack IR generated; simple programs execute on Forth; Forth output
   round-trips through `reg-rs`.
9. **Risks** — Unicode parsing complexity; splicing ambiguity
   (tuple-as-one-value vs tuple-as-splice); OCaml-subset limits on
   the parser host; COR24 ISA constraints on the Forth runtime.

## Style

- Clear, terse Markdown. ASCII-only (`markdown-checker -f
  docs/prd.md` should pass). Short paragraphs; bullet lists welcome;
  code blocks for examples.
- Under ~200 lines total.

## Do not

- Do not write the grammar, design, lowering, or plan docs in this
  step.
- Do not edit outside this repo.
- Do not invent features not discussed in `research.txt`.

## If blocked

If you discover that a needed reference is missing (e.g., the
parser host `sw-cor24-ocaml` lacks a feature needed later), note it
in the Risks section — do not start working around it. Upstream bugs
or missing features are filed as GitHub issues in later steps.

## Finish

- `git add docs/prd.md` and relevant `.agentrail/` files.
- Commit with message like `docs: draft Tuplet PRD`.
- `agentrail complete --summary "drafted docs/prd.md from
  research.txt" --reward 1 --actions "synthesized research notes
  into a PRD"`.
