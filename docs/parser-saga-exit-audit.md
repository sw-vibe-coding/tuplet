# Parser Saga Exit Audit

This audit checks the active `tuplet-parser` saga against the parser
exit criteria in `docs/plan.md` and the demo-parity path in
`docs/tuplet-implementation-parity-plan.md`.

## Summary

The parser is ready to feed a narrow first checker slice:

- tuple variable signatures shaped like `*coord2 -> (x y)`;
- tuple-pattern assignment shaped like `a, b <- coord2`;
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
| Tuple signature groups | Partial | `*coord2 -> (x y)` is parsed and memory-backed. Verb signatures with input and output tuples, such as `*max2 (a b) -> (q r)`, are not yet represented. |
| Tuple-pattern assignment LHS | Pass for current checker slice | `a, b <- coord2` parses as a `pattern` group and memory-backed fixture. Checker can validate arity from this shape. |
| Tuple literals and expression groups | Gap | Parenthesized groups are shallow. Call forms and tuple-valued expression groups are not yet tuple-shaped enough for checker/lowering parity. |
| Syntax declaration then later code parses documented AST | Pass for current matcher | Registry-backed syntax matching works, including multi-slot captures from real source. |
| Registry stores temporary token/template slices | Pass as skeleton | Current registry stores string token slices. This is intentionally temporary and must evolve before macro expansion is considered complete. |
| Tuple-shaped macro representation | Gap | Syntax match dumps still expose raw template, slot, and expansion lists rather than tuple-shaped macro AST. |
| Longest-match wins / first-declared ties | Pass | Covered by `tuplet_parse_syntax_longest` and `tuplet_parse_syntax_tie`. |
| Deterministic AST dump | Pass | Existing parser baselines are stable reg-rs outputs. |
| Unknown-token errors | Pass | Covered by `tuplet_parse_unknown_error`. |
| Unmatched-template errors | Gap / design decision | No registered-template miss diagnostic exists today; the parser falls back to kernel parsing when no syntax template matches. |

## Regression Slice

The audit regression slice is:

- `tuplet_parse_signature`
- `tuplet_parse_tuple_assign`
- `tuplet_parse_memory_signature`
- `tuplet_parse_memory_tuple_assign`
- `tuplet_parse_memory_syntax`
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
- verb signatures with input tuples;
- call expressions;
- tuple literal semantics;
- tuple-shaped macro expansion.

## Recommended Next Parser Cleanup

Before declaring parser parity, add one focused parser cleanup step:

1. Add or explicitly defer `prim/forth "WORD"` and colon-kernel forms.
2. Add a real-source fixture for a multi-output verb signature with an
   input tuple.
3. Add call and tuple-expression parse fixtures, even if the checker
   initially rejects them.
4. Decide whether an unmatched registered template should be a parser
   error or a kernel fallback, then lock that behavior with a baseline.
5. Replace or annotate raw syntax slot dumps with the intended
   tuple-shaped macro representation.

After that, the saga can either close as parser-complete or hand a
small, explicit deferral list to the parity plan.
