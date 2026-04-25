# Tuplet Lexer

Implementation lives under `src/`; build/run via
`scripts/run-ml.sh <file.ml>` which delegates to
`sw-cor24-ocaml` and strips the Pascal runtime's source-echo
prefix so downstream output is the program's output only.

## Smoke baseline

`tuplet_build_skeleton` -- runs `src/lex_main.ml` and verifies
the cleaned output is `tuplet-lexer skeleton\n`.

```
REG_RS_DATA_DIR=work/reg-rs reg-rs run -p tuplet_build_skeleton
```

## Source-of-truth references

- `docs/grammar.md` -- what the lexer must produce (token shape,
  Unicode aliases).
- `docs/kernel.md` -- the dynamic-literal-registry contract:
  `Lexer.add_literal` (or equivalent) lets the parser register
  new literal tokens at runtime as `syntax` declarations are
  processed.

## OCaml-subset notes

The `sw-cor24-ocaml` interpreter is more restrictive than full
OCaml. Confirmed during scaffold:

- Top-level `print_endline "..."` works.
- The `let () = ...` form does **not** parse (use top-level
  expressions instead, or `let _ = ...`).

Further constraints will be discovered and noted as the lexer
implementation grows.
