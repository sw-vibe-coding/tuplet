# Reusable Lexer Entrypoint

Split `src/lexer.ml` so it defines lexer functions without running
the dump driver at module load time. Added `src/lexer_dump_main.ml`
as the explicit fixture entrypoint and updated
`scripts/run-lexer-fixture.sh` to load and strip both source files.

Validated representative lexer baselines after the split:

- `tuplet_lex_ident_simple`
- `tuplet_lex_literal_registered`

The next parser handoff remains gated on
`sw-embed/sw-cor24-ocaml#24`: qualified constructors from imported
modules parse, but evaluating the Lexer-to-Parser constructor bridge
currently produces `EVAL ERROR`.
