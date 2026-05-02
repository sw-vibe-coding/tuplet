# Lexer Parser Handoff

Real-source lexer-to-parser handoff is unblocked and covered by
memory-backed regressions.

Implemented:

- `scripts/run-ml-memory.sh` stages a terminated memory image before
  loading fixture bytes at `0x080000`, so the lexer no longer depends
  on incidental memory contents after a fixture.
- `scripts/run-ml-memory.sh` now passes an explicit configurable
  `cor24-run` wall limit (`TUPLET_COR24_WALL_SECONDS`, default 180)
  because the GC-enabled OCaml host needs more than the emulator's
  default wall-time budget for full Tuplet stacks.
- `src/lex_bridge.ml` converts lexer byte-list payload tokens into the
  parser's string-payload token type.
- `src/lex_parse_main.ml` validates one-pass real-source parsing for
  assignment input.
- `src/lex_parse_register_main.ml` validates the syntax path: parse
  the first memory-backed line as a syntax declaration, then parse the
  following line against the updated registry.
- `scripts/repro-ocaml-issue28.sh` remains as the upstream host repro
  proving the two-pass memory-backed token path now works.

Regressions:

- `tuplet_parse_memory_assignment` parses `foo <- 42` from
  memory-loaded source and dumps the assignment AST.
- `tuplet_parse_memory_syntax` parses a memory-loaded `* syntax ...`
  declaration followed by `do body while cond end` and dumps the
  expected `syntax-match` AST.

Upstream blockers verified fixed:

- `sw-cor24-ocaml#28`: two-pass memory-backed Tuplet parse no longer
  traps after syntax registration.
- `sw-cor24-ocaml#29`: mid-eval GC/reclaim now lets the standalone
  Tuplet repro print `1275`; Tuplet closed the issue after validating
  assignment and syntax memory regressions against host `11e2264`.
