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
file's bytes via `OCAML_STDIN`, runs `src/lexer.ml` plus
`src/lexer_dump_main.ml`, strips the Pascal runtime's source-echo
prefixes, and prints just the emitted tokens. reg-rs baselines
drive this script per fixture.

`src/lexer.ml` intentionally has no top-level `start_lexer` call:
it is the reusable lexer module. `src/lexer_dump_main.ml` is the
dump CLI entrypoint. Keeping those separate lets later parser
acceptance tests import the lexer without dumping tokens as a
side effect.

The lexer can also read from a memory-loaded fixture instead of UART.
`Lexer.use_memory_input 524288` switches `lexer_getc` to read bytes via
the OCaml host's `peek` primitive, with the fixture loaded at
`0x080000`. This mirrors the batch-image pattern used by other COR24
interpreters and keeps source fixtures separate from UART output.

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

## Multi-byte tokens (`<-`, `->`)

Lookahead-driven. After reading `<` (60), peek the next byte;
if it's `-` (45) emit `TLArrow`. Otherwise `<` is unknown and
the lookahead byte is threaded back as the next token's
leading byte.

`-` is now lookahead-driven too: read the next byte; if it's
`>` (62) emit `TRArrow`. Otherwise the token is `TMinus` and
the read byte is the next leading byte. The parser later
folds `TMinus` followed by `TInt` into a negative literal.

## Single-byte punctuation

| Byte | Char | Token        |
|------|------|--------------|
| 40   | `(`  | `TLParen`    |
| 41   | `)`  | `TRParen`    |
| 123  | `{`  | `TLBrace`    |
| 125  | `}`  | `TRBrace`    |
| 44   | `,`  | `TComma`     |
| 95   | `_`  | `TUnderscore`|
| 42   | `*`  | `TMint`      |

## Unicode Lexing

The kernel glyph aliases listed in `docs/glyphs.md` fold to the
same parser-facing tokens as their ASCII spellings. The current
`sw-cor24-ocaml` runner feeds Unicode runtime input to `getc` as
the glyph codepoint's low byte, so the lexer matches those stable
runtime byte values directly:

| Glyph | Runtime byte | Fold | Token |
|-------|--------------|------|-------|
| BULLET | 34 | `*` | `TMint` |
| BLACK SMALL SQUARE | 170 | `*` | `TMint` |
| LEFTWARDS ARROW | 144 | `<-` | `TLArrow` |
| LEFTWARDS LONG ARROW | 245 | `<-` | `TLArrow` |
| RIGHTWARDS ARROW | 146 | `->` | `TRArrow` |
| RIGHTWARDS DOUBLE ARROW | 210 | `->>` | `TRArrow` then `TUnknown 62` |

The wider suggested glyph table remains user-extension territory
for later `*syntax` declarations; lexer-level folding is limited
to these kernel aliases.

## Per-let if-chain depth limit

Discovered while adding identifier dispatch: the host appears
to silently truncate or fail to compile a `let` body whose
top-level `if-then-else` chain has more than 14 branches.
With 15 branches the function definition itself parses, but
subsequent `let _ = ...` evaluations all return EVAL ERROR.

Workaround: split a long dispatch into a helper function.
`lex_loop` has 7 branches and routes the rest to `lex_other`
(9 branches), each well within the limit. No upstream issue
filed yet -- the symptom is "EVAL ERROR on a function
defined with > 14 branches" but the failure mode might be
something else entirely (memory, expression-tree size). If
encountered again with a small repro, file then.

## Identifier ambiguity rule

A bare `_` followed by whitespace, EOF, or any non-ident-
continuation byte is `TUnderscore` (template slot marker).
A `_` followed by an ident-continuation byte (letter, digit,
or `_`) starts an identifier whose first byte is `_`. Decided
at lex time by `lex_uscore`: read the lookahead byte; if
ident-cont, recurse into `lex_ident_after`; otherwise emit
`TUnderscore` and thread the lookahead back as the next
token's leading byte.

## Identifier body

Letters (`A`-`Z` or `a`-`z`), digits, and `_` form the
continuation; trailing `?` is allowed once at the end. The
parser later interprets a trailing digit run as an arity
suffix (`coord2` -> arity 2).

Pre-registration "keywords" (e.g., `if`, `then`, `else`,
`while`) lex as `TIdent` -- the lexer doesn't know about
keywords. Once a `*syntax T expand E` declaration registers
a literal token, the parser tells the lexer to switch its
classification via the dynamic literal registry.

## Dynamic Literal Registry

The parser can call `add_literal <bytes>` before a lexing pass
to register template literal words introduced by earlier
`*syntax` declarations. Completed identifiers are compared
against the registered byte lists. A match dumps as:

```
LIT    if
```

Unregistered names still dump as `IDENT`. The registry is
append-only for a lexer run; callers that need a different
literal set start a fresh run and register the needed literals
before lexing source.

`scripts/run-lexer-fixture.sh` also supports a test-only
registration prelude in fixture bytes:

- SOH (`0x01`) begins literal registrations.
- Space (`0x20`) separates literal names.
- STX (`0x02`) ends registrations and normal source lexing
  begins.

For example, bytes for `0x01 if then 0x02 if else 0x03`
register `if` and `then`, then lex `if else` as `LIT if`,
`IDENT else`, `EOF`. Real parser integration should call
`add_literal` directly rather than emitting this prelude.

## Source-ingestion vs runtime-input gotcha

`getc` reads from the SAME UART stream that feeds source code
to the runtime. After source ingestion completes (EOT, 0x04),
runtime input begins. **The lexer driver `let _ = ... lex_loop
...` MUST be the last top-level statement** in the file: any
top-level statements after it would still be in the source
stream, and `getc` would consume their bytes instead of
runtime input. Discovered the hard way in step 005.

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
