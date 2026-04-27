# Step: lex-arrows-and-punct

Extend `src/lexer.ml` to recognize the remaining single-byte
punctuation and the multi-byte arrows: `<-`, `->`, `(`, `)`,
`{`, `}`, `,`, `_`, plus the mint operator `*` (the proposed
ASCII fallback for the BULLET / BLACK SMALL SQUARE glyph).

Builds on the byte-stream + one-byte-lookahead pattern from
step 004. The only new mechanic is multi-byte tokens (`<-`,
`->`).

## Scope

- Add token variants: `TLArrow`, `TRArrow`, `TLParen`,
  `TRParen`, `TLBrace`, `TRBrace`, `TComma`, `TUnderscore`,
  `TMint`.
- Extend `dump_tok` with print rules for each (LARROW, RARROW,
  LPAREN, RPAREN, LBRACE, RBRACE, COMMA, USCORE, MINT).
- Multi-byte tokens: `<-` and `->`. After seeing `<` (60),
  read the next byte; if it's `-` (45) emit `TLArrow`,
  otherwise emit `TUnknown 60` and thread the read byte back
  as the next token's leading byte. Same pattern for `>` (62)
  followed by... wait, only `->` exists, not `>-`. So the `-`
  case needs care: after seeing `-`, peek the next byte. If
  it's `>` (62) emit `TRArrow`; otherwise the token is
  `TMinus` and the read byte is the next leading byte.

  Reshape: `-` is no longer single-byte. It's lookahead-
  driven: `- >` -> `TRArrow`, `- <anything-else>` -> `TMinus`
  with `<anything-else>` as next leading byte. Update step
  004's `TMinus` handling accordingly. Add `TMinus`'s
  fixture (`numeric_minus`) check still passes.

- Single-byte mappings:
  - `40` -> `TLParen`
  - `41` -> `TRParen`
  - `123` -> `TLBrace`
  - `125` -> `TRBrace`
  - `44` -> `TComma`
  - `95` -> `TUnderscore`
  - `42` -> `TMint`

## Fixtures + baselines (`tests/lexer/`)

- `arrows_l.input` -- `<-\x03` -> `LARROW EOF`
- `arrows_r.input` -- `->\x03` -> `RARROW EOF`
- `arrows_lt_only.input` -- `<\x03` -> `UNK 60 EOF`
- `parens.input` -- `( )\x03` -> `LPAREN RPAREN EOF`
- `braces.input` -- `{ }\x03` -> `LBRACE RBRACE EOF`
- `comma_uscore.input` -- `, _\x03` -> `COMMA USCORE EOF`
- `mint.input` -- `*coord2\x03` -> `MINT UNK 99 ...` (will
  emit unknown bytes for letters until step 006 adds idents)
- `minus_then_int.input` -- `-7\x03` -> `MINUS INT    7 EOF`
  (regression check that adding `->` lookahead didn't break
  bare `-`)
- `assign_one_line.input` -- `x <- 3\x03`. Letters are still
  unknown (UNK 120) until idents come; we just check the
  arrow + int lex correctly.

reg-rs: `tuplet_lex_arrows_<name>` per fixture. Run twice;
confirm stable.

## Update docs/lexer.md

Add the multi-byte lookahead pattern to the "Numeric lexing"
section (or a new "Multi-byte tokens" subsection). Note the
specific gotcha: `-` is lookahead-driven, not single-byte.

## Do not

- Do not lex identifiers, names, or arity-suffix logic in this
  step. That's the next step.
- Do not edit outside this repo.

## Finish

- Stage src/lexer.ml, tests/lexer/<arrow|parens|braces|
  comma_uscore|mint|minus_then_int|assign_one_line>.input,
  work/reg-rs/, docs/lexer.md, full .agentrail/ delta.
- Commit. Push.
- `agentrail complete --summary "added L/R arrows with lookahead,
  parens/braces/comma/uscore/mint singles, refactored TMinus to
  use lookahead path; 9 reg-rs baselines green" --reward 1
  --actions "extended lex_loop with multi-byte dispatch;
  TMinus repath" --next-slug lex-identifiers --next-prompt
  <prompt-for-next-step>`.

## Suggested next step

`lex-identifiers` -- recognize names: ASCII letter start,
letter/digit/underscore body, optional trailing `?`. Trailing
digit run is significant (arity suffix). Recognize Unicode
glyphs in the alias table as folding to the ASCII form (start
small: just the BULLET mint glyph and the various arrow
glyphs if Espanso would feed them). Reg-rs baselines per name
shape.
