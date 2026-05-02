# Parser Saga Exit Audit

This audit checks the active `tuplet-parser` saga against the parser
exit criteria in `docs/plan.md` and the demo-parity path in
`docs/tuplet-implementation-parity-plan.md`.

## Summary

The parser is ready to feed a narrow first checker slice:

- tuple variable signatures shaped like `▪coord₂ ───‣ ⎛x y⎠`;
- tuple-pattern assignment shaped like `a , b ⟵ coord₂`;
- syntax declarations and later syntax-match statements;
- deterministic dumps and deterministic fatal parser errors;
- memory-backed source handoff from the lexer into the parser.

The parser saga is not complete against the full planned parser
surface. The remaining gaps should be closed or explicitly deferred
before this repo claims parser parity with the Forth, Rust, and
DiscoveryOne implementations.

## Exit Criteria Check

| Criterion | Status | Evidence / gap |
|---|---|---|
| Kernel `syntax` form | Pass | `tuplet_parse_syntax_register`, `tuplet_parse_syntax_verb_register`, and `tuplet_parse_memory_syntax`. |
| Kernel `<-`, comma, parens, braces, `#`, `_` | Partial | Existing token and shallow group parsing covers these shapes. The parser still emits scaffolding `ATOM` and `GROUP` nodes for several forms. |
| Kernel `:` and `prim/forth` | Gap | The lexer/parser do not yet have a real colon form or string-backed `prim/forth` form. This blocks prelude/Forth escape parity. |
| Tuple signature groups | Pass for first checker slice | `▪coord₂ ───‣ ⎛x y⎠` is parsed from real memory-backed UTF-8 source by `tuplet_parse_memory_canonical_signature`. Verb signatures with input and output tuples are covered by `tuplet_parse_verb_signature` and `tuplet_parse_memory_canonical_verb_signature`. |
| Tuple-pattern assignment LHS | Pass for current checker slice | `a , b ⟵ coord₂` parses as a `pattern` group once normalized. Checker can validate arity from this shape. |
| Tuple literals and expression groups | Partial | `tuplet_parse_call` and `tuplet_parse_tuple_expr` lock shallow tuple-shaped groups. Nested expression semantics still belong to checker/lowering work. |
| Syntax declaration then later code parses documented AST | Pass for current matcher | Registry-backed syntax matching works, including multi-slot captures from real source. |
| Registry stores temporary token/template slices | Pass as skeleton | Current registry stores string token slices. This is intentionally temporary and must evolve before macro expansion is considered complete. |
| Tuple-shaped macro representation | Gap | Syntax match dumps still expose raw template, slot, and expansion lists rather than tuple-shaped macro AST. |
| Longest-match wins / first-declared ties | Pass | Covered by `tuplet_parse_syntax_longest` and `tuplet_parse_syntax_tie`. |
| Deterministic AST dump | Pass | Existing parser baselines are stable reg-rs outputs. |
| Unknown-token errors | Pass | Covered by `tuplet_parse_unknown_error`. |
| Unmatched-template errors | Deferred by design | `tuplet_parse_syntax_no_match` locks the current behavior: a registered-template miss falls back to kernel parsing. A future syntax strictness rule can replace this with a diagnostic. |

## Regression Slice

The audit regression slice is:

- `tuplet_parse_signature`
- `tuplet_parse_tuple_assign`
- `tuplet_parse_memory_signature`
- `tuplet_parse_memory_tuple_assign`
- `tuplet_parse_memory_syntax`
- `tuplet_parse_verb_signature`
- `tuplet_parse_call`
- `tuplet_parse_tuple_expr`
- `tuplet_parse_syntax_no_match`
- `tuplet_parse_syntax_longest`
- `tuplet_parse_syntax_tie`
- `tuplet_parse_unknown_error`
- `tuplet_parse_group_error`

All passed at the time this audit was written.

## Checker Entrance

Checker work can start if it is scoped to the supported parser subset:

- name resolution for tuple variables;
- arity extraction from tuple signature output groups;
- arity checking for tuple-pattern assignment;
- diagnostics for unbound names and assignment arity mismatch;
- syntax-match slot shapes only as raw captured spans.

Checker work should not assume support yet for:

- `prim/forth`;
- colon definitions;
- nested call expressions;
- tuple literal semantics beyond shallow tuple shape;
- tuple-shaped macro expansion.

## Recommended Next Parser Cleanup

The remaining parser deferrals are:

1. `prim/forth "WORD"` requires lexer support for string literals and
   a settled representation for the slash-bearing keyword.
2. Colon-kernel forms require lexer support for `:` and a decision on
   whether colon is surface Tuplet or only emitted Forth.
3. Raw syntax slot dumps should later be replaced or annotated with
   the intended tuple-shaped macro representation.

Those deferrals should not block the first checker slice, but they
must be resolved before the prelude and Forth emitter sagas.
