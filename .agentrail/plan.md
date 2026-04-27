# Saga: tuplet-parser

## Goal

Build the registry-based Tuplet parser described in docs/plan.md and docs/kernel.md. The parser consumes lexer tokens, parses kernel forms, maintains the syntax registry, and applies longest-match template expansion to produce a deterministic AST dump.

## Source of truth

- docs/grammar.md -- surface grammar and lexical token meanings.
- docs/kernel.md -- syntax declaration semantics, registry rules, and kernel/prelude split.
- docs/design.md -- AST shape and downstream expectations.
- docs/plan.md -- saga 2 entrance and exit criteria.

## In scope

- AST data types and deterministic AST dump format.
- Parser entry point over lexer token streams.
- Kernel forms: syntax declarations, mint declarations/signatures, assignment arrows, comma-separated values, parens, comments, underscore slots, braces for anonymous verbs, and prim/forth token forms as far as specified by the kernel.
- Syntax registry storing templates and expansions.
- Longest-match-wins template matching, first-declared-wins on ties.
- reg-rs baselines for parser skeleton, kernel-only programs, syntax registration, template expansion, ambiguity resolution, and parser errors.

## Out of scope

- Type/arity checking.
- IR lowering.
- Forth emission.
- Full prelude.

## End state

- src/parser.ml and supporting AST/registry files exist.
- Parser can process one syntax declaration and parse later code using its template.
- AST dumps are deterministic and covered by reg-rs baselines.
- docs/plan.md marks tuplet-parser done when exit criteria are met.
