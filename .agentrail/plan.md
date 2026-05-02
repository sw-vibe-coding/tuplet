# Saga: tuplet-checker

## Goal

Implement the first Tuplet checker over the parser AST, starting with name resolution and tuple arity checks for the parser-complete subset.

## Source of truth

- docs/plan.md -- saga 3 entrance and exit criteria.
- docs/grammar.md -- arity rules and tuple/call semantics.
- docs/design.md -- checker and typed-AST expectations.
- docs/parser-saga-exit-audit.md -- parser subset and explicit deferrals.
- docs/tuplet-implementation-parity-plan.md -- demo-parity priorities.

## In scope

- src/checker.ml and a deterministic checker dump driver.
- Tuple variable/signature environment from parser signature nodes.
- Name resolution for tuple variables and call callees in the supported parser subset.
- Arity checks for tuple-pattern assignment and shallow call argument tuple shapes.
- Stable pass/fail reg-rs baselines.
- Checker docs explaining current scope and parser deferrals.

## Out of scope

- IR lowering.
- Interpretation or Forth emission.
- prim/forth and colon forms until lexer/parser deferrals are resolved.
- Full macro expansion beyond raw syntax-match slot spans.

## End state

- Checker pass fixtures produce deterministic typed/check dumps.
- Checker fail fixtures produce deterministic diagnostics for unbound names and arity mismatch.
- coord2 and basic tuple destructuring are checked deterministically.
