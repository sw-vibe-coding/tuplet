# Step: phased-plan

Write `docs/plan.md` -- the durable phased plan for Tuplet. Turn
the Phase 0-8 arc (summarized in `docs/prd.md` and the
`tuplet-scaffold` saga plan) into a concrete list of follow-up
sagas, each with clear entrance and exit criteria. This is the
document the user (and the next-session agents) consult to know
what comes after `tuplet-scaffold` closes.

## Required sections

1. **Arc summary (one paragraph).** Phase 0 (this scaffold) ->
   lexer -> parser -> arity checker -> stack IR -> reference
   interpreter -> Forth emitter -> demos. Each phase is one
   saga.

2. **Saga index (table).** Columns: saga name, phase, one-line
   goal, status (upcoming / in-progress / done). Scaffold is
   in-progress; all others upcoming.

3. **Per-saga sections.** For each of the following sagas,
   write:
   - **Goal** (1-2 sentences).
   - **Entrance criteria** (what must be true before the saga
     starts -- usually "prior saga complete, docs X Y Z in
     place, reg-rs baselines for X still green").
   - **Exit criteria** (what the saga's final commit must look
     like -- concrete, testable).
   - **Key deliverables** (files, tests).
   - **Primary risks** (short list).

   Cover all of these, in order:

   - `tuplet-lexer` -- produces a stream of tokens from `.tup`
     source. Implement in the OCaml subset hosted on
     `sw-cor24-ocaml`. Golden reg-rs baselines per test input.
   - `tuplet-parser` -- builds the AST in `docs/design.md` from
     a token stream. Golden AST-dump baselines.
   - `tuplet-checker` -- name resolution + arity checking per
     `docs/grammar.md` Arity rules. Baselines for both pass and
     fail (expected error message text).
   - `tuplet-ir` -- AST -> stack IR per `docs/design.md`.
     Golden IR-dump baselines.
   - `tuplet-interp` -- reference interpreter over the stack
     IR. Produces expected output for each example program,
     used as an oracle in later Forth comparison.
   - `tuplet-forth-emit` -- IR -> Forth per `docs/lowering.md`,
     emitted into `work/generated/*.fs`, executed under
     `cor24-run`, output compared against the interpreter via
     reg-rs.
   - `tuplet-demos` -- an example gallery: 6-10 `.tup`
     programs demonstrating tuple decls, destructuring, all
     multi-output verbs, call-with-splice, and at least one
     program that exercises the COR24 LED via a wrapped
     builtin. Each demo has its own reg-rs baseline.

4. **Cross-cutting concerns.** A short list of things every
   saga must honor:
   - Do not edit outside this repo.
   - Missing features / bugs in `sw-cor24-ocaml` or
     `sw-cor24-forth` are GitHub issues, not local workarounds.
   - Every commit pushed in the same session.
   - `.agentrail/` delta committed whole (see CLAUDE.md
     section 4).
   - `markdown-checker -f <path>` clean on every edited .md.

5. **Out-of-scope (still).** A reminder of the non-goals from
   `docs/prd.md`: no type inference, no modules, no exceptions,
   no GC heap, no float beyond percent literals. Phase 9+ may
   revisit, but not in this plan.

## Style

- ASCII-only (`markdown-checker -f docs/plan.md`).
- Under ~350 lines.
- Tables + short bullet lists over prose.

## Reference

- `docs/prd.md` -- goals, non-goals, success criteria.
- `docs/grammar.md` -- surface syntax.
- `docs/design.md` -- AST and IR.
- `docs/lowering.md` -- Forth emission spec.
- `.agentrail/plan.md` -- the scaffold saga plan (for tone
  and structure).

## Do not

- Do not restate the full PRD or grammar here -- link out to
  them.
- Do not pre-commit to implementation details beyond what the
  prior docs already fix.
- Do not start any saga; this step only writes the plan.

## Finish

- Commit code + full .agentrail/ delta + push.
- This is the **final step of the tuplet-scaffold saga**. Run:

  ```
  agentrail complete --summary "wrote docs/plan.md; tuplet-scaffold
  exit criteria met" --reward 1 --actions "enumerated the seven
  follow-up sagas with entrance/exit criteria" --done
  ```

  The `--done` flag closes the saga. No `--next-slug` here; the
  next saga (`tuplet-lexer`) is initiated by the user or a fresh
  agent session running `agentrail init`.
