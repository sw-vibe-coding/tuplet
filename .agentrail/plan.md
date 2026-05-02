# Saga: tuplet-ir

## Goal

Lower the checked Tuplet AST subset into a deterministic stack IR, staying within the parser/checker-complete kernel slice before any interpreter or Forth emitter work.

## Source of truth

- docs/plan.md -- phase 4 entrance and exit criteria.
- docs/design.md -- Stack IR instruction set and tuple order convention.
- docs/lowering.md -- future Forth mapping; use only as downstream guidance.
- docs/checker.md -- checker output and current supported AST subset.
- docs/kernel.md -- prim/forth and anonymous-verb boundaries.

## In scope

- IR data representation in the OCaml subset.
- Deterministic IR dump driver and reg-rs baselines.
- Lowering for the checker-complete subset: tuple signatures, tuple-pattern assignment, shallow calls, integer/percent/symbol/name atoms, and tuple loads/stores.
- Clear docs for current IR scope and deferrals.

## Out of scope

- Forth emission.
- Reference interpreter.
- Prelude implementation.
- Full macro expansion or nested expression semantics beyond the current parser/checker AST.
- Anonymous-verb thunks and prim/forth until represented by parser/checker.

## End state

- Representative checked/parser-backed programs lower to stable IR dumps.
- At minimum: coord2 tuple declaration + assignment, tuple destructuring, call-site tuple splicing shape, and fail-fast behavior when checker rejects input.
- IR docs identify exactly what is ready for the next saga and what is still deferred.