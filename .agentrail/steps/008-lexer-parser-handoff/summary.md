# Lexer Parser Handoff Blocker

The real-source parser acceptance path is gated on
`sw-embed/sw-cor24-ocaml#24`.

Validated state before blocking:

- Upstream `sw-cor24-ocaml` is up to date at `7c9b873`.
- Issue #24 remains open.
- The minimized constructor bridge still prints `EVAL ERROR`:
  `Lexer.TLArrow -> Parser.TLArrow`.
- Lexer-only and parser-only regression slices still pass:
  `tuplet_lex_ident_simple` and `tuplet_parse_syntax_multislot`.

No local workaround was committed. The next step after #24 is fixed
is to add `src/lex_parse_main.ml`, a source fixture runner, and
reg-rs baselines for assignment plus a syntax declaration followed
by a matching statement.
