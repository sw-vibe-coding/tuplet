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

## Lexing model: byte stream

The lexer is a byte-stream consumer. Input arrives via `getc`
(one byte at a time, 0..255); output token payload bytes are
emitted via `putc` (one byte at a time). This matches the
host's natural API and Forth's `KEY` / `EMIT` convention -- the
runtime is a byte-oriented system end-to-end.

### EOF sentinel

`getc` blocks at end of input rather than returning a sentinel.
The lexer uses `\x03` (ETX, ASCII 3) as the in-band EOF marker.
Every fixture file ends with one ETX byte; the lexer's main
loop returns when `getc` yields 3.

The choice of ETX is arbitrary but stable: it is not a valid
character anywhere in Tuplet source and survives shell variable
round-tripping (which would strip `\x00`).

### Driver

`scripts/run-lexer-fixture.sh <fixture.input>` feeds a fixture
file's bytes via `OCAML_STDIN`, runs `src/lexer.ml`, strips the
Pascal runtime's source-echo prefixes, and prints just the
emitted tokens. reg-rs baselines drive this script per fixture.

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

`src/lexer.ml`'s `dump_tok` writes each token on its own line
via `putc` byte-by-byte: a fixed-width prefix for the kind
(stored as an `int list` of byte values, e.g. `[73; 78; 84;
32; 32; 32; 32]` is `"INT    "`), the payload bytes (for
`THash`) or the integer rendered as decimal digits (for
`TInt`/`TPct`), and a final `putc 10` for LF. Examples:

```
HASH    hello world
INT    42
PCT    50
MINUS
UNK     <byte-int>
EOF
```

### Numeric lexing

Digits accumulate into the integer directly via `n * 10 + (b -
48)` while `is_digit b` holds. The terminating non-digit byte
is returned alongside the number; the main loop threads it
back as the next token's leading byte (one-byte lookahead via
a `pre` parameter, with `0` as the "no pending byte" sentinel
since `0x00` is not a valid Tuplet source byte). If the
post-digit byte is `%` (37) the token is `TPct`, otherwise
`TInt` and the lookahead byte starts the next token.

`-` (`TMinus`) is its own single-byte token; the parser later
folds `TMinus` followed by `TInt` into a negative literal.

## OCaml-subset notes (current)

The `sw-cor24-ocaml` interpreter, since the recent fixes,
supports enough of OCaml to host nontrivial parser code
naturally. Confirmed:

- **Top-level `let X = E` declarations** persist across lines
  (`sw-embed/sw-cor24-ocaml#3`).
- **User-defined variant types** with payload constructors
  (`sw-embed/sw-cor24-ocaml#2`).
- **Multi-file modules**: filename `math.ml` becomes module
  `Math`, accessed cross-file as `Math.add`. Multiple files
  passed as args: `run-ocaml.sh math.ml main.ml`. Top-level
  `let` in each file becomes a member of that module.
- **String escapes (`\n`, `\t`, `\\`, `\"`)** and **3+ element
  tuples** (`sw-embed/sw-cor24-ocaml#4`).
- Function-shorthand `let f x = ...` works.
- `let rec`, lists, pairs, options, pattern matching, qualified
  names (`List.length`, `List.rev`).
- `print_endline`, `print_int`, `string_of_int`, string concat
  via `^`, `int_of_string`.
- Byte I/O: `getc : unit -> int`, `putc : int -> unit`,
  `read_line : unit -> string`.

The Tuplet lexer chooses the byte-stream `getc`/`putc` path
because it matches the host's natural API and the Forth runtime
target -- not because of a missing string-stdlib feature.

## Open upstream limitations

These are absent; the lexer's byte-stream design avoids needing
them, but they would simplify future work:

- **`String.get` / `s.[i]` / `String.sub` / `Char.chr` /
  `Char.code` / `print_string`** -- per-character string access
  and char/int interop. The lexer side-steps the gap by reading
  bytes via `getc` and emitting via `putc`, never assembling
  strings from bytes nor pulling characters out of strings.
- **No string literals in match patterns.** `match x with "foo"
  -> ...` does not parse. With variants available, the lexer
  uses variant constructors for tag dispatch instead.
- **No `(* ... *)` block comments.** OCaml host code uses no
  comments for now.

`sw-embed/sw-cor24-ocaml#4` (string `\n` escapes; 3+ element
tuples) was actually resolved by upstream fixes verified via
re-probing today; the issue may not yet be marked closed but
the runtime accepts both.

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
