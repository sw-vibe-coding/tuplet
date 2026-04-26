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

The PoC uses idiomatic OCaml variants -- now supported upstream
since `sw-embed/sw-cor24-ocaml#2` was implemented (see commit
`17732be` on `feat/wip`):

```ocaml
type token =
  | TIdent of string
  | TInt of int
  | TPct of int
  | TLArrow
  | TRArrow
  | TLParen
  | TRParen
  | TLBrace
  | TRBrace
  | TComma
  | TUnderscore
  | THash of string
  | TLiteral of string
  | TEOF
  | TMint
```

Constructor payloads carry the relevant data; nullary
constructors have none. Dispatch via `match`.

### Dump format

`src/token_test.ml` prints one token per line via repeated
`print_endline` (because string `\n` escapes are still absent
-- `sw-embed/sw-cor24-ocaml#4` open). Each variant maps to a
fixed-width name plus optional payload. See `dump_tok` in
`src/token_test.ml` for the full table.

## OCaml-subset notes (current)

The `sw-cor24-ocaml` interpreter, since the recent fixes,
supports enough of OCaml to host nontrivial parser code
naturally. Confirmed:

- **Top-level `let X = E` declarations** persist across lines
  (`sw-embed/sw-cor24-ocaml#3`, fixed in `9449a05`). Helpers
  defined once, reused freely.
- **User-defined variant types** with payload constructors
  (`sw-embed/sw-cor24-ocaml#2`, fixed in `17732be`).
- Function-shorthand `let f x = ...` works.
- `let rec`, lists, pairs, options, pattern matching, qualified
  names (`List.length`, `List.rev`).
- `print_endline`, `print_int`, `string_of_int`, string concat
  via `^`.

## Open upstream limitations

These remain; workarounds noted are still applied and small
enough to not pollute the host code:

- **No string `\n` escapes** (`sw-embed/sw-cor24-ocaml#4`).
  Backslash-n in a literal is two literal chars; LF in a string
  terminates the source line. Workaround: per-line
  `print_endline` for any "newline-separated" output.
- **No 3+ element tuples** (`sw-embed/sw-cor24-ocaml#4`).
  Workaround: nested pairs `(a, (b, c))` if ever needed; with
  variants now available, rarely needed.
- **No string literals in match patterns.** `match x with "foo"
  -> ...` does not parse. With variants now available,
  workarounds are rarely needed -- use a variant constructor
  instead of a string tag. Not separately filed yet; if we hit
  a real need, file then.
- **No `(* ... *)` block comments.** Use `# ...` or a comment
  variant if needed inside Tuplet; OCaml host code uses no
  comments for now.

## Implementation pattern (current)

Each source file under `src/` is a self-contained program in
the natural OCaml style: top-level `type ...` declaration(s),
top-level `let ...` bindings, then `let _ = ...` to drive the
side-effects of the main flow. Multi-line, with each top-level
declaration on its own line. See `src/token_test.ml` for a
reference shape.

Match arms must currently fit on one line (no multi-line
`match | ... | ...`); single-line dispatch via `match x with
PAT1 -> ... | PAT2 -> ...` is the idiom even when the arm
list is long.

There is no module system / cross-file import. Each `.ml` file
is its own program. Code that several test files would share
is duplicated for now.
