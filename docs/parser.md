# Tuplet Parser

The parser saga starts with a minimal AST and token-consumer
skeleton. It does not implement Tuplet grammar yet; this first
step establishes file layout, source handoff, and deterministic
AST dump output.

## Current Shape

`src/ast.ml` defines the initial dumpable AST:

```
PROGRAM
TOKEN  mint
TOKEN  ident:coord2
END
```

`src/parser.ml` defines a parser-facing token type mirroring the
lexer token surface and a `parse` function over a token list.
For now it turns non-comment, non-EOF tokens into flat `AToken`
nodes. Comments are skipped and EOF terminates the program.

`src/parser_main.ml` is a smoke driver with a fixed token list.
Later parser steps will replace the fixed token source with real
lexer handoff and kernel grammar parsing.

## Boundaries

This skeleton intentionally does not implement template matching,
syntax declarations, checking, IR lowering, or Forth emission.
Those belong to later parser and downstream sagas.
