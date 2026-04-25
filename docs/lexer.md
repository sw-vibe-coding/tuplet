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

## Token representation

Pending `sw-embed/sw-cor24-ocaml#2` (user-defined variants), the
PoC encodes tokens as **nested pairs**:

```
(kind_int, (int_payload, str_payload))
```

`kind_int` is a small integer code; the payload pair carries
either an int (`TInt`, `TPct`) or a string (`TIdent`, `THash`,
`TLiteral`) -- the unused slot is `0` or `""`. Nesting is needed
because `sw-embed/sw-cor24-ocaml#4` (3+ element tuples) is also
absent. Pattern match on `kind_int` to dispatch.

### Kind codes

| Code | Token         | Carries                     |
|------|---------------|-----------------------------|
| 0    | `TIdent`      | str = name                  |
| 1    | `TInt`        | int = value                 |
| 2    | `TPct`        | int = 0..100                |
| 3    | `TLArrow`     | --                          |
| 4    | `TRArrow`     | --                          |
| 5    | `TLParen`     | --                          |
| 6    | `TRParen`     | --                          |
| 7    | `TLBrace`     | --                          |
| 8    | `TRBrace`     | --                          |
| 9    | `TComma`      | --                          |
| 10   | `TUnderscore` | --                          |
| 11   | `THash`       | str = comment text          |
| 12   | `TLiteral`    | str = registered literal    |
| 13   | `TEOF`        | --                          |
| 14   | `TMint`       | -- (the minting glyph)      |

### Dump format

`src/token_test.ml` prints one token per line via repeated
`print_endline` (because string `\n` escapes are absent --
`sw-embed/sw-cor24-ocaml#4`). Format:

```
IDENT  <name>
INT    <int>
PCT    <int>
LARROW
RARROW
LPAREN
RPAREN
LBRACE
RBRACE
COMMA
USCORE
HASH   <text>
LIT    <name>
EOF
MINT
```

A trailing `0` line is the runtime printing the program's `()`
return value as zero. Documented and accepted; not stripped.

## OCaml-subset notes

The `sw-cor24-ocaml` interpreter is more restrictive than full
OCaml. Discovered constraints:

- Top-level `print_endline "..."` works.
- `let () = ...` does **not** parse. Use top-level expressions
  or `let _ = ...`.
- **No top-level let bindings** without `in EXPR`. Each top-
  level expression is independent; there is no cross-line
  scope. Filed: `sw-embed/sw-cor24-ocaml#3`.
- **No user-defined variant types.** `type t = A | B` does not
  parse. Filed: `sw-embed/sw-cor24-ocaml#2`. Workaround: tagged
  pairs with integer kind codes (above).
- **No string `\n` escapes.** Backslash-n inside a string is
  treated as a literal `\\n` and the LF terminates the source
  line. Filed: `sw-embed/sw-cor24-ocaml#4`. Workaround: emit
  per-line via repeated `print_endline`.
- **No 3+ element tuples.** Pairs only. Filed:
  `sw-embed/sw-cor24-ocaml#4`. Workaround: nested pairs.
- **String literals in patterns parse-error.** Match on string
  literals like `("INT", n)` is not supported. Workaround: use
  integer kind codes for tags.

These all have workarounds in place; none block the PoC. The
upstream issues are filed for visibility and so the workarounds
can be unwound as the interpreter grows.

## Implementation pattern

Given the constraints above, every nontrivial source file under
`src/` is **one giant single-line expression** built from nested
`let rec NAME = fun ARG -> EXPR in NEXT` chains. Wrap helpers
inline at the point of use. Document the pattern at the top of
each file with a short comment block.

When `sw-embed/sw-cor24-ocaml#3` (top-level lets) lands, source
files can be split into per-line declarations and shared across
files via copy-include or a future module system; until then,
single-file giant-expression is the way.
