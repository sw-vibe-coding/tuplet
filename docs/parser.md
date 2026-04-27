# Tuplet Parser

The parser saga starts with a minimal AST and token-stream
consumer. It does not implement Tuplet grammar yet; this phase
establishes file layout, source handoff, and deterministic AST
or error dump output.

## Current Shape

`src/ast.ml` defines the initial dumpable AST. A successful flat
token stream dumps as statement nodes:

```
PROGRAM
STMT
ATOM   mint
ENDSTMT
STMT
ATOM   ident:coord2
ENDSTMT
END
```

`src/parser.ml` defines a parser-facing token type mirroring the
lexer token surface and a `parse` function over a token list.
For now it consumes one non-comment token per flat statement,
returning the remaining token stream explicitly from
`parse_statement`. Comments are skipped as trivia and EOF
terminates the program.

Unknown lexer tokens are parser errors:

```
ERROR  unknown-token:64
```

`src/parser_main.ml` and `src/parser_error_main.ml` are smoke
drivers with test token streams. Later parser steps will replace
these test streams with real lexer handoff and kernel grammar
parsing.

## Token Stream Contract

The parser accepts the same token variant surface as the lexer:
identifiers, integer and percent literals, arrows, delimiters,
commas, underscore slots, mint, comments, EOF, minus, literals,
and unknown bytes. Current parser smoke drivers use string
payloads for names and literals; the direct lexer handoff will
settle the payload representation when the parser and lexer are
wired together.

The parser contract for this phase is:

- `THash` is trivia and never appears in the AST.
- `TEOF` terminates the program.
- `TUnknown` terminates parsing with a deterministic error dump.
- All other tokens are accepted as single-token flat statements.

## Boundaries

This skeleton intentionally does not implement template matching,
syntax declarations, checking, IR lowering, or Forth emission.
Those belong to later parser and downstream sagas.
