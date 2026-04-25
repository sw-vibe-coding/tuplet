# Step: kernel-boundary-design

Write `docs/kernel.md` -- the explicit kernel/prelude split for
Tuplet, grounded in the architectural decision that **extensions
should be used for as much of the language as possible**, in the
Forth and Lisp tradition: a tiny irreducible kernel + a prelude
written in Tuplet itself.

This document is load-bearing for every later saga. Every later
saga decision must rest on the boundary drawn here. Get it wrong
and the rest of the project relitigates it.

## Required sections

1. **Philosophy (one paragraph).** State the principle: the kernel
   only contains what cannot be expressed in Tuplet itself. Every
   operator, every control-flow construct, every tuple helper that
   *can* live in `.tup` source *must* live there. Cite Forth
   (immediate words define `IF`, `BEGIN`, etc.) and Lisp
   (`define-syntax` defines almost the whole language) as
   precedents.

2. **Litmus test.** A simple rule: a form belongs in the kernel
   only if its definition would have to bottom out in itself or
   in something not yet available. If it can be defined using
   earlier-declared things plus `prim/forth` (the raw-Forth
   escape hatch), it goes in the prelude.

3. **Kernel inventory (table).** The exact list of primitive
   forms. Columns: form, role, why it cannot be in the prelude.
   At minimum cover:
   - `syntax <template> -> <verb>` declaration form
   - `:` verb-body form (or whatever syntax binds a verb name to
     a body)
   - `<-` assignment (kernel-only because every later
     declaration uses it)
   - `,` value separator and `()` grouping (kernel-only because
     parsing depends on them)
   - `#` line comment
   - `_` slot marker inside a `syntax` template
   - anonymous-verb literal `{ ... }` (or chosen syntax) -> emits
     a Forth `:NONAME` and yields an xt
   - `prim/forth "<word>"` raw escape -- emits a literal Forth
     word into output (the only way the prelude reaches kernel
     primitives)
   - the `prim/` namespace: list each `prim/X` the prelude is
     allowed to call (e.g., `prim/add`, `prim/sub`, `prim/mul`,
     `prim/slashmod`, `prim/less`, `prim/dup`, `prim/drop`,
     `prim/swap`, `prim/over`, `prim/emit`, `prim/dot`,
     `prim/cr`, `prim/space`, `prim/store`, `prim/fetch`,
     `prim/create`, `prim/comma`)

   Justify each entry by the litmus test. Anything not on this
   list is library.

4. **Prelude inventory (table).** Forms that move to `lib/std.tup`
   and are defined using only kernel features + earlier prelude
   entries. Columns: form, depends on, one-line definition
   sketch. Cover:
   - `+ - * < =` -- thin wrappers over `prim/add` etc.
   - `>= <= <> not && ||`
   - `max min div max2 min2 div2` -- per `docs/lowering.md`,
     written in `.tup` using kernel primitives
   - `if _ then _ else _ end` via `syntax`, body in `.tup`
     calling `std/if3`, where `std/if3` is itself built from
     `prim/forth "IF"` etc. -- but show the body in Tuplet, not
     raw Forth
   - `while _ do _ end`
   - `match _ with _` (sketch only; can be more detailed in a
     later saga)
   - tuple variable declaration sugar (the `name -> (f1 f2)` form
     is potentially library too if we factor right -- discuss)
   - `plot` itself

5. **Bootstrap order.** A short ordered list. The kernel loads
   first. Then `lib/std.tup` loads in a specific order so each
   `syntax` declaration's body uses only earlier-declared
   things. Document the order and the rule: "no forward
   references in the prelude."

6. **`syntax` semantics (precise).** Three subsections:
   - **Template grammar.** A template is a sequence of literal
     tokens and `_` slots, e.g. `if _ then _ else _ end`.
     Literal tokens become reserved on registration.
   - **Slot evaluation.** Every `_` is implicitly thunked: at
     parse time it is wrapped in an anonymous verb, and the
     bound verb receives an xt for the slot. The bound verb
     decides which slots to `EXECUTE`.
   - **Matching policy.** Longest-match wins; ties resolve to
     first-declared. Document the consequence (later `syntax`
     declarations cannot shadow earlier ones with shorter
     templates) and call this out as a known limitation.

7. **Worked example.** Define `if/then/else` end-to-end. Show:
   - the prelude `.tup` source for `syntax if _ then _ else _ end -> std/if3`
   - the prelude `.tup` source for `: std/if3 (cond t e) <- ...`
     using `prim/forth` to emit the actual Forth `IF/ELSE/THEN`
   - the lowered Forth output for a use site like
     `result <- if x > 0 then 1 else 0 - 1 end`
   - the IR generated for that use site

8. **Implications for the saga arc.** The previously planned
   seven sagas (`tuplet-lexer`, `tuplet-parser`, `tuplet-checker`,
   `tuplet-ir`, `tuplet-interp`, `tuplet-forth-emit`,
   `tuplet-demos`) become **eight**, with `tuplet-prelude`
   inserted between `tuplet-forth-emit` and `tuplet-demos`. List
   the new arc and one-line goal per saga. Reshape the others:
   - `tuplet-parser` must implement the `syntax` registry and
     template matcher -- not a fixed grammar.
   - `tuplet-checker` arity-checks against the registry -- no
     hardcoded operator list.
   - `tuplet-prelude` writes `lib/std.tup` and proves the
     bootstrap.
   - `tuplet-demos` exit criterion: every demo uses prelude
     features only, with `if`, `while`, and `match` defined in
     `.tup`.

9. **Risks and unknowns.** Honest list:
   - The OCaml-subset host parser must support template
     matching from day one; a fixed grammar parser is not a
     stepping stone.
   - Anonymous-verb literals generate `:NONAME` words; need
     `sw-cor24-forth` to support `:NONAME` (verify or file
     upstream issue).
   - Mixfix ambiguity will show up; longest-match is a PoC
     compromise, not a real solution.
   - "Most of the language in itself" is a spectrum; the PoC
     target is roughly 50% (all operators, all control flow,
     all tuple helpers in `.tup`; parser stays in OCaml).

10. **Note for the next step.** The pending step `phased-plan`
    (now at saga position 9) has a prompt that predates this
    architecture decision. When that step runs, the agent
    should write `docs/plan.md` based on **this kernel
    document, not the stale prompt verbatim**. Specifically: it
    must enumerate eight sagas (not seven) and reflect the
    `tuplet-prelude` saga and the registry-based parser/checker
    redesign. Add a one-line warning at the top of `docs/plan.md`
    pointing readers to this kernel doc as the source of truth.

## Style

- ASCII-only (`markdown-checker -f docs/kernel.md`).
- Aim for ~250 lines; ok to go to 350 if the worked example
  needs the room.
- Tables and short fenced code blocks beat prose.

## Reference

- `docs/prd.md`, `docs/grammar.md`, `docs/design.md`,
  `docs/lowering.md` -- the existing spec layer; this doc
  refines and supersedes the parts about which features are
  "built-in."
- `~/github/sw-embed/sw-cor24-forth/forth.s` for confirmed
  primitive words.
- `~/github/sw-embed/sw-cor24-forth/README.md` for the documented
  word list. Verify `:NONAME` -- if absent, file an upstream
  issue and note it in the kernel doc's risks section.

## Do not

- Do not implement anything. This step writes a single design
  document.
- Do not edit outside this repo.
- Do not paper over upstream gaps -- if `:NONAME` or any kernel
  primitive is missing from `sw-cor24-forth`, file an issue and
  document under risks.

## Finish

- Commit code + full .agentrail/ delta + push.
- `agentrail complete --summary "wrote docs/kernel.md; defined
  the kernel/prelude boundary and reshaped the saga arc to 8
  sagas with tuplet-prelude" --reward 1 --actions "synthesized
  the Forth+Lisp tradition into an explicit kernel inventory
  and bootstrap order"`.
- Do **not** auto-queue a next step; the existing `phased-plan`
  step (now at position 9) is already queued and will pick up
  next session with the deviation note in section 10 of
  `docs/kernel.md`.
