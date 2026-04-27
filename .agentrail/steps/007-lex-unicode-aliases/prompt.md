# Step: lex-unicode-aliases

Fold the Unicode kernel glyphs from `docs/glyphs.md` to their
ASCII canonical form at lex time. After this step, sources
typed via Espanso/Emacs/XCompose using the Unicode forms
produce the same tokens as their ASCII equivalents -- the
parser sees only ASCII-canonical tokens.

## Scope

Recognize and fold these Unicode glyphs (multi-byte UTF-8) to
their ASCII canonical:

| Glyph (UTF-8 bytes)            | Codepoint | ASCII fold  | Canonical token |
|--------------------------------|-----------|-------------|-----------------|
| BULLET           (E2 80 A2)    | U+2022    | `*`         | TMint           |
| BLACK SMALL SQUARE (E2 96 AA)  | U+25AA    | `*`         | TMint           |
| LEFTWARDS ARROW   (E2 86 90)   | U+2190    | `<-`        | TLArrow         |
| LEFTWARDS LONG ARROW (E2 9F B5)| U+27F5    | `<-`        | TLArrow         |
| RIGHTWARDS ARROW (E2 86 92)    | U+2192    | `->`        | TRArrow         |
| RIGHTWARDS DOUBLE ARROW (E2 87 92) | U+21D2| `->>`       | (future test arrow; for now TRArrow + extra) |

Out of scope for this step: the wider "suggested glyphs"
table in `docs/glyphs.md` (math relations, type symbols,
Greek letters). Those are user-extension territory and don't
need lexer-level recognition until `*syntax` declarations
use them in templates.

## Approach

Multi-byte UTF-8 detection at the lex_loop entry. A byte in
the range 0xC0..0xFF is a UTF-8 start byte; read 1-3
continuation bytes to assemble the full codepoint, then
match against the table above and emit the corresponding
token. Continuation bytes (0x80..0xBF) seen alone become
TUnknown (malformed input).

Implementation: a new helper `lex_utf8 b acc` that:
- Inspects the high bits of b to determine sequence length
  (110xxxxx = 2 bytes, 1110xxxx = 3 bytes, 11110xxx = 4
   bytes; the listed glyphs are all 3-byte sequences).
- Reads the continuation bytes via getc.
- Computes the codepoint.
- Dispatches: 0x2022 / 0x25AA -> TMint; 0x2190 / 0x27F5 ->
  TLArrow; 0x2192 -> TRArrow; else TUnknown <codepoint-low-byte>.

Watch the 14-branch limit. If utf8 dispatch grows long, push
into a sub-helper.

## Fixtures + baselines

Fixtures are binary files containing the UTF-8 bytes
directly. Use `printf '\xe2\x80\xa2\x03'` etc.

- `unicode_bullet.input` -- BULLET + ETX -> `MINT EOF`
- `unicode_blacksq.input` -- BLACK SMALL SQUARE + ETX -> `MINT EOF`
- `unicode_larrow.input` -- LEFTWARDS ARROW + ETX -> `LARROW EOF`
- `unicode_rarrow.input` -- RIGHTWARDS ARROW + ETX -> `RARROW EOF`
- `unicode_long_larrow.input` -- LEFTWARDS LONG ARROW + ETX -> `LARROW EOF`
- `unicode_mixed.input` -- BULLET + ASCII space + `coord2`
  + space + RIGHTWARDS ARROW + space + `(x y)` + ETX
  -> `MINT IDENT coord2 RARROW LPAREN IDENT x IDENT y RPAREN EOF`

reg-rs baseline per fixture: `tuplet_lex_unicode_<name>`.

## Update docs/lexer.md

Add a "Unicode lexing" section linking to `docs/glyphs.md`
and noting the multi-byte detection logic.

## Do not

- Do not lex the wider Greek/math/type glyph table; those are
  user-extension territory.
- Do not introduce a glyph translation table file separate
  from the lexer source -- a single inline if-chain in
  lex_utf8 is fine for the small kernel set.
- Do not edit outside this repo.

## If blocked

- If string output of the multi-byte glyph confuses the
  reg-rs baseline (the wrapper strips runtime echoes that
  contain UTF-8), document and fix the wrapper rather than
  routing around it.
- If the host's getc returns the high-bit byte sign-extended
  (negative number), file a sw-cor24-ocaml issue.

## Finish

- Stage src/lexer.ml, tests/lexer/unicode_*.input,
  work/reg-rs/, docs/lexer.md, full .agentrail/ delta.
- Commit. Push.
- `agentrail complete --summary "Unicode kernel glyph folding;
  6 reg-rs baselines; 40 of 40 green" --reward 1 --actions
  "lex_utf8 helper for 2-3 byte UTF-8; codepoint-level
  dispatch; ASCII-canonical tokens emitted" --next-slug
  lex-literal-registry --next-prompt <prompt-for-next-step>`.

## Suggested next step

`lex-literal-registry` -- add a runtime literal registry the
parser can extend at `*syntax` time. The lexer needs a
`Lexer.add_literal "if"` function that adds a string to a
registered-literals list; subsequent ident lex compares
against that list and emits `TLiteral name` instead of
`TIdent name` for matches.

This is the load-bearing step that bridges into the parser
saga. Implementation: a `ref` to a `string list` (or
equivalent — the host now supports `ref`). Add an
add_literal function. In lex_ident_after, after assembling
the name's bytes, compare against the registry and choose
TLiteral vs TIdent.
