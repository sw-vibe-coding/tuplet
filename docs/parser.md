# Tuplet Parser

The parser saga starts with a minimal AST and token-stream
consumer. It is moving toward a tuple-shaped AST: syntax
declarations, function signatures, tuple values, and assignment
patterns should preserve field/shape information instead of
collapsing into permanent token lists. The current phase
establishes file layout, source handoff, and deterministic AST or
error dump output.

## Current Shape

`src/ast.ml` defines the initial dumpable AST. Today it still uses
scaffolding nodes such as `STMT`, `ATOM`, and `GROUP`. A successful
kernel-form token stream dumps as statement nodes with structured
children:

```
PROGRAM
STMT   mint
ATOM   mint
ATOM   ident:coord2
ATOM   rarrow
GROUP  paren
ITEM   ident:x
ITEM   ident:y
ENDGROUP
ENDSTMT
END
```

`src/parser.ml` defines a parser-facing token type mirroring the
lexer token surface and a `parse` function over a token list.
For now it parses one kernel-form statement from the token stream,
returning the remaining token stream explicitly from
`parse_statement`. Comments are skipped as trivia and EOF
terminates the program. The parser is split from `src/ast.ml` and
`src/registry.ml`, relying on the host's multi-file module path
rather than concatenating sources.

Unknown lexer tokens are parser errors:

```
ERROR  unknown-token:64
```

`src/parser_main.ml`, `src/parser_assign_main.ml`,
`src/parser_syntax_main.ml`, `src/parser_error_main.ml`, and the
syntax-registry drivers are smoke drivers with test token streams.
Later parser steps will replace these test streams with real lexer
handoff, registry-driven template matching, and tuple-shaped AST
nodes.

The lexer is now importable without side effects: `src/lexer.ml`
defines tokenization and `src/lexer_dump_main.ml` owns the token
dump entrypoint. `src/lex_bridge.ml` converts lexer tokens with
byte-list payloads into parser tokens with string payloads. The
single-source memory-backed handoff is covered by
`tuplet_parse_memory_assignment`.

Multi-source syntax acceptance is still gated on
`sw-embed/sw-cor24-ocaml#26`: memory-loaded lexer bytes are readable,
but converting syntax-sized memory-backed token lists currently
truncates before the `expand` delimiter.

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
- `TLParen` and `TLBrace` open shallow structured groups.
- `TComma` and `TUnderscore` are preserved as kernel atoms.
- A stream containing `TLArrow` dumps as `STMT   assign`.
- A stream beginning with `TMint` dumps as `STMT   mint`, unless
  it is the syntax declaration head.
- `TMint` followed by `TIdent "syntax"` or `TLiteral "syntax"`
  parses as a syntax declaration head. The parser splits tokens
  before `expand` or `TRArrow` into `GROUP  template` and tokens
  after it into `GROUP  expansion`.
- Parsed syntax declarations are inserted into `src/registry.ml`
  with declaration order, mode (`expand` or `verb`), template
  token slice, and expansion token slice. The registry is a
  skeleton that stores and dumps entries.
- Later parses in the same process consult the registry before
  falling back to kernel parsing. The current matcher is a narrow
  first slice: `_` captures the token span up to the next template
  literal, longest matching template wins, and first-declared wins
  on ties. Matched statements dump as `STMT   syntax-match` with
  mode, template, slots, and expansion groups. Slot captures are
  delimited by `slot-start` markers in the current dump format.

## Tuple-First Direction

The scaffolding dump is not the final parser design. The parser
should evolve toward named tuple-shaped nodes:

- Function signatures are `input_tuple -> output_tuple` transforms.
- Tuple literals and tuple type/signature groups preserve field
  names and positional fields.
- Assignment LHS forms are tuple patterns, not only identifier
  lists.
- Syntax declarations currently register template/expansion token
  slices and can match later token streams. Later macro work should
  store and rewrite tuple-shaped AST where possible, replacing the
  temporary flat slot dump with explicit tuple-shaped slot nodes.
- Compiler pass APIs can later carry tuple-shaped state such as
  `(source, tokens, diagnostics, ast, ...)`.

## Boundaries

This skeleton intentionally does not implement template matching,
checking, IR lowering, tuple-space coordination, or Forth emission.
Those belong to later parser and downstream sagas.
