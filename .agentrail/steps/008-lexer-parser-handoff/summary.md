# Lexer Parser Handoff Blocker

The real-source parser acceptance path is gated on
`sw-embed/sw-cor24-ocaml#26`.

Validated state before blocking:

- Upstream `sw-cor24-ocaml` is rebuilt at `0b7230b` plus the local
  uncommitted upstream hex-literal parser edit already present in that
  worktree.
- Issue #24 is closed and verified: the minimized constructor bridge
  now prints `larrow` for `Lexer.TLArrow -> Parser.TLArrow`.
- Issue #25 is closed and verified: `peek`/`poke` pass upstream, and
  Tuplet can load fixture bytes at `0x080000`.
- Single-source memory-backed lexer-to-parser handoff works for an
  assignment fixture. The committed regression is
  `tuplet_parse_memory_assignment`.
- Multi-source syntax fixtures should not be forced through UART. The
  intended path is now memory-backed: parse the first line as a syntax
  declaration, then parse the remaining memory image against the
  updated registry.
- That intended path is gated on #26: memory lexer dump sees all tokens,
  and literal token conversion works, but converting a syntax-sized
  memory-backed token list truncates/stalls before `ident:expand`.
- Lexer-only and parser-only regression slices still pass:
  `tuplet_lex_ident_simple` and `tuplet_parse_syntax_multislot`.

No local workaround was committed. The next step after #26 is fixed is
to add the memory-backed syntax declaration plus matching statement
regression.
