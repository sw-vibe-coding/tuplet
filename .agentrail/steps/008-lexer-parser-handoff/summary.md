# Lexer Parser Handoff Blocker

The real-source parser acceptance path is gated on
`sw-embed/sw-cor24-ocaml#25`.

Validated state before blocking:

- Upstream `sw-cor24-ocaml` is rebuilt at `2882e3f`.
- Issue #24 is closed and verified: the minimized constructor bridge
  now prints `larrow` for `Lexer.TLArrow -> Parser.TLArrow`.
- Single-source lexer-to-parser handoff works for an assignment
  fixture via `OCAML_STDIN`.
- Multi-source syntax fixtures should not be forced through UART.
  Other COR24 repos use memory-loaded batch images, especially
  `sw-cor24-apl`: raw text is loaded with `--load-binary` at
  `0x080000` and enabled by patching a pointer cell at `0x09FF00`.
- `sw-cor24-ocaml` does not yet expose a `peek`/memory-byte input
  primitive to OCaml programs, so #25 tracks the needed host feature.
- Lexer-only and parser-only regression slices still pass:
  `tuplet_lex_ident_simple` and `tuplet_parse_syntax_multislot`.

No local workaround was committed. The next step after #25 is fixed
is to add a memory-backed source fixture runner, then reg-rs baselines
for assignment plus a syntax declaration followed by a matching
statement.
