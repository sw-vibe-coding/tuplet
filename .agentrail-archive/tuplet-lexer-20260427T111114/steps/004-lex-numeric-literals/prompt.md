# Step: lex-numeric-literals

Extend `src/lexer.ml` to recognize integer literals (with
optional leading `-`) and percent literals (digit run followed
by `%`). Build on the byte-stream design from step 003.

## Scope

- Add token variants: `TInt of int`, `TPct of int`,
  `TMinus` (kept as a separate token because `-` is also the
  unary minus / subtraction; the parser disambiguates later).
- Add `TUnknown of int` for any unrecognized leading byte so
  the lexer reports rather than infinite-loops on bad input.
- New lex states triggered by the leading byte:
  - `48..57` (digits): collect digits, parse via int_of_string;
    if the next byte is `37` (`%`), consume it and emit `TPct`,
    otherwise emit `TInt`.
  - `45` (`-`): emit `TMinus`. (The parser later folds
    `TMinus` followed by `TInt` into a negative literal; the
    lexer stays simple.)
- Update `dump_tok` to print INT, PCT, MINUS lines.

## Fixtures + baselines

Add under `tests/lexer/`:
- `numeric_zero.input` -- `0\x03` -> `INT    0` then `EOF`.
- `numeric_basic.input` -- `42\x03` -> `INT    42` then `EOF`.
- `numeric_pct.input` -- `50%\x03` -> `PCT    50` then `EOF`.
- `numeric_pct_100.input` -- `100%\x03` -> `PCT    100`.
- `numeric_minus.input` -- `-7\x03` -> `MINUS` then `INT    7`.
- `numeric_with_ws.input` -- `  42  50%  \x03` ->
  `INT    42` then `PCT    50` then `EOF`.
- `numeric_with_comment.input` -- `42 # answer\n\x03` ->
  `INT    42` then `HASH    answer` then `EOF`.

reg-rs baseline per fixture: `tuplet_lex_numeric_<name>`. All
must run twice and stay stable.

## Reuse `int_of_string`

The host has `int_of_string : string -> int` (see
`docs/stdin-and-getc.md` interactive-loops example). The
challenge: the lexer collects digits as `int list` (byte
values). Convert to a string for `int_of_string`. Two paths:

- (a) Build the integer directly in the lexer by accumulating
  `n * 10 + (byte - 48)` as bytes are consumed. No conversion
  needed. Cleaner for the byte-stream model.
- (b) Build a string somehow for `int_of_string`. Without
  `Char.chr` / `String.sub`, this is hard.

**Pick (a).** It's the natural byte-stream approach.

## Update docs/lexer.md

Add the new token variants to the kind table; document the
"digits accumulate via `n * 10 + (b - 48)` while the byte is
in the digit range" approach.

## Do not

- Do not lex identifiers, punctuation, or arrows yet.
- Do not edit outside this repo.

## If blocked

- If `int_of_string` is unexpectedly absent or buggy, file
  `gh issue create --repo sw-embed/sw-cor24-ocaml`. Path (a)
  side-steps it anyway.
- If string output gaps ever bite (e.g., we need to format
  something the host can't) file the relevant issue.

## Finish

- Stage src/lexer.ml, tests/lexer/numeric_*.input,
  work/reg-rs/, docs/lexer.md, full .agentrail/ delta.
- Commit. Push.
- `agentrail complete --summary "TInt + TPct + TMinus +
  TUnknown; 7 reg-rs baselines green; digits accumulated via
  byte-stream, no string conversion needed" --reward 1
  --actions "extended lex_loop with digit and %, dispatch on
  leading byte" --next-slug lex-arrows-and-punct --next-prompt
  <prompt-for-next-step>`.

## Suggested next step

`lex-arrows-and-punct` -- recognize `<-`, `->`, `(`, `)`, `{`,
`}`, `,`, `_`. Multi-byte tokens (`<-`, `->`) need a one-byte
lookahead; introduce a small "peeked" buffer or refactor the
loop to thread a "current byte" parameter. Reg-rs baselines
per token form.
