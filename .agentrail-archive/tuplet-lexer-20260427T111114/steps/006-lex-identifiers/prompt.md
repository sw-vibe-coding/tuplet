# Step: lex-identifiers

Recognize ASCII identifiers in the lexer: a letter or `_`
start, followed by any combination of letters, digits, or `_`,
optionally ending in `?`. Trailing-digit run on the name is
preserved as part of the name; the parser later interprets it
as an arity suffix (e.g., `coord2` -> arity 2).

Builds on the byte-stream + one-byte-lookahead pattern from
steps 003-005.

## Scope

- Add token variant: `TIdent of int list`. The payload is the
  byte sequence of the identifier name (including any trailing
  digits and optional trailing `?`).
- Extend `dump_tok` with an `IDENT  <name>` print rule.
- Extend `lex_loop`: when the leading byte is a letter
  (`A`-`Z` or `a`-`z`) or `_`, enter `lex_ident`. **Note:**
  `_` is currently `TUnderscore` (template slot marker). The
  ambiguity is resolved at lex time by lookahead -- a
  standalone `_` (followed by whitespace, comma, paren, etc.)
  is `TUnderscore`; `_` followed by an identifier-continuation
  char is the start of an identifier. Document this rule
  carefully in `docs/lexer.md`.
- Identifier continuation: letter / digit / `_` / trailing `?`.
- After collecting the name bytes, the post-name byte threads
  back as the next token's leading byte.

## Fixtures + baselines (`tests/lexer/`)

- `ident_simple.input` -- `foo\x03` -> `IDENT  foo` then EOF
- `ident_with_digits.input` -- `coord2\x03` -> `IDENT  coord2`
- `ident_with_qmark.input` -- `success?\x03` -> `IDENT  success?`
- `ident_uppercase.input` -- `Red\x03` -> `IDENT  Red`
- `ident_underscore_inside.input` -- `safe_div\x03` -> `IDENT  safe_div`
- `ident_underscore_lead.input` -- `_x\x03` -> `IDENT  _x`
- `ident_underscore_alone.input` -- `_\x03` -> `USCORE EOF`
  (regression: standalone `_` stays as TUnderscore)
- `ident_keyword_like.input` -- `if then else\x03` ->
  `IDENT  if`, `IDENT  then`, `IDENT  else`, EOF
  (lexer doesn't know about keywords; that's the parser's
  job. Keywords are introduced as `TLiteral` only after a
  `*syntax` declaration registers them. Until then,
  potentially-keyword names lex as plain identifiers.)
- `ident_full_decl.input` --
  `*coord2 -> (x y)\x03` ->
  `MINT IDENT  coord2 RARROW LPAREN IDENT  x IDENT  y RPAREN EOF`
  (the canonical first declaration form; integration check)

reg-rs: `tuplet_lex_ident_<name>` per fixture. Run twice;
confirm stable.

## OCaml-subset shape reminder

The current lexer is single-line per top-level statement
(no block comments, magic numbers throughout) because:

- block comments at the file head + multi-line match in
  helper functions caused source-ingestion to interleave
  with `getc` calls in unexpected ways (discovered in step
  005);
- restoring the if-chain + magic numbers without comments
  produced reliable results.

Refactoring the lexer back to char literals + comments +
multi-line match is **not** part of this step; if attempted,
do it as a separate clean-up commit AFTER this step's
deliverable lands and is regression-tested.

## Update docs/lexer.md

- Document the `_` ambiguity rule.
- Add `TIdent` to the token table / dump format section.
- Note that pre-registration "keywords" lex as identifiers.

## Do

1. Add `TIdent of int list` variant.
2. Add `lex_ident` helper similar to `collect_comment` --
   reads identifier-continuation bytes until a non-cont byte
   appears, returns `(int_list, next_byte)`.
3. Wire into `lex_loop`: dispatch to `lex_ident` when the
   leading byte is a letter or `_`-followed-by-cont.
4. Update `dump_tok` with the IDENT case.
5. Create the 9 fixture files.
6. Capture reg-rs baselines.

## Do not

- Do not implement the dynamic-literal registry yet; that's
  step 007.
- Do not lex Unicode aliases yet; ASCII only.
- Do not edit outside this repo.

## If blocked

- If the `_` ambiguity rule trips a corner case unexpectedly,
  document the failure in `docs/lexer.md` and choose a
  simplification (e.g., always treat `_` followed by a
  letter as an ident -- the standalone-`_` case stays
  TUnderscore via the natural lookahead-byte path).
- Missing string-stdlib features that bite: file an upstream
  issue. Don't work around in tuplet.

## Finish

- Stage src/lexer.ml, tests/lexer/ident_*.input,
  work/reg-rs/, docs/lexer.md, full .agentrail/ delta.
- Commit. Push.
- `agentrail complete --summary "TIdent with letter/digit/_/?
  body; underscore-vs-uscore disambiguation; 9 reg-rs
  baselines; 34 total" --reward 1 --actions "extended
  lex_loop with letter/underscore dispatch; lex_ident reads
  continuation bytes" --next-slug lex-unicode-aliases
  --next-prompt <prompt-for-next-step>`.

## Suggested next step

`lex-unicode-aliases` -- fold the Unicode glyph table from
`docs/glyphs.md` to ASCII canonical at lex time. Specifically
the kernel forms (BULLET / BLACK SMALL SQUARE -> `*`;
LEFTWARDS ARROW -> `<-`; RIGHTWARDS ARROW -> `->`; etc.).
This is multi-byte UTF-8 detection; treat as a one-step
table lookup at the lexer entry point, before single-byte
dispatch.
