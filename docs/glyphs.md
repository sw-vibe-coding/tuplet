# Tuplet Glyph Alphabet

What characters Tuplet's lexer recognizes, and what users
typically reach for when minting their own constructs. Two
tiers:

1. **Minimal alphabet** -- the codepoints the kernel and
   prelude depend on. Every Tuplet implementation must lex
   these (or an exact ASCII alias).
2. **Suggested glyphs** -- the wider palette users dip into
   when minting operators and identifiers. The compiler
   doesn't privilege them; they're just code points the user
   community has agreed feel right.

Tuplet is glyph-first. This file embeds canonical glyphs directly so
docs, demos, and tests do not drift back to ASCII-first examples. See
`docs/notation.md` for the concise source of truth.

## Minimal alphabet

Every form below has an ASCII fallback. The lexer folds the
Unicode form to the same parser-facing internal token at lex time,
so AST output and error messages can stay normalized regardless of
how the user typed it.

### Mint operator

| Role | Canonical Unicode | Aliases | ASCII fallback |
|------|-------------------|---------|----------------|
| Mint | BLACK SMALL SQUARE `▪` (U+25AA) | none; `•` is not mint | `*` |

### Arrows

| Role            | Canonical Unicode               | Aliases              | ASCII |
|-----------------|---------------------------------|----------------------|-------|
| Assign          | LONG LEFTWARDS ARROW `⟵` (U+27F5) | LEFTWARDS ARROW (U+2190) | `<-`  |
| Map / signature | HEAVY MAPPING ARROW `───‣` (U+2500 x3 + U+2023) | RIGHTWARDS ARROW (U+2192) | `->` |
| Test arrow      | RIGHTWARDS ARROW `⟶` (U+27F6) | RIGHTWARDS ARROW (U+2192) | `->>` |

### Brackets

| Role           | Canonical Unicode                    | Aliases | ASCII |
|----------------|--------------------------------------|---------|-------|
| Group / call   | LEFT/RIGHT PARENTHESIS UPPER HOOK `⎛` `⎠` | LEFT/RIGHT WHITE PARENTHESIS | `(` `)` |
| Operator action | MEDIUM FLATTENED PARENTHESIS `❪` `❫` | none | deferred |
| Block / xt lit | LEFT/RIGHT CURLY BRACKET UPPER HOOK  | -       | `{` `}` |
|                | (U+23A7 / U+23AB)                    |         |       |

### Punctuation

| Role           | Codepoint            | ASCII   |
|----------------|----------------------|---------|
| Value separator| COMMA (U+002C)       | `,`     |
| Slot marker    | LOW LINE (U+005F)    | `_`     |
| Line comment   | NUMBER SIGN (U+0023) | `#`     |

### Numerals

| Role        | Codepoint               | ASCII |
|-------------|-------------------------|-------|
| Digits      | U+0030 .. U+0039        | `0`-`9` |
| Percent     | PERCENT SIGN (U+0025)   | `%`   |
| Minus       | HYPHEN-MINUS (U+002D)   | `-`   |

### Identifier alphabet (basic)

ASCII letters U+0041..U+005A and U+0061..U+007A; digits
U+0030..U+0039; LOW LINE U+005F; trailing QUESTION MARK
U+003F or MODIFIER LETTER GLOTTAL STOP (U+02C0). Trailing
digit run encodes arity (e.g., `coord2` -> arity 2).

## Suggested glyphs for user-minted code

The lexer doesn't bake these in; they're either:

- characters the lexer treats as identifier-extension
  characters (so they can appear inside a name like
  `if<U+2248>`, the approx-equal-conditional verb), OR
- characters the user puts in a `▪syntax` template's literal
  positions, which the lexer surfaces as `TLiteral` once
  registered.

Encouraged categories follow.

### Math relations

| Codepoint | Name                       | Common use                                  | ASCII alias |
|-----------|----------------------------|---------------------------------------------|-------------|
| U+2248    | ALMOST EQUAL TO            | approx-equal verb                           | `~~`        |
| U+2260    | NOT EQUAL TO               | inequality                                  | `<>`        |
| U+2264    | LESS-THAN OR EQUAL         | leq                                         | `<=`        |
| U+2265    | GREATER-THAN OR EQUAL      | geq                                         | `>=`        |
| U+00B1    | PLUS-MINUS SIGN            | tolerance binder                            | `+/-`       |
| U+221E    | INFINITY                   | sentinel value                              | `inf`       |

### Math operators

| Codepoint | Name                       | Common use                                  | ASCII alias |
|-----------|----------------------------|---------------------------------------------|-------------|
| U+00D7    | MULTIPLICATION SIGN        | multiplication                              | `*`         |
| U+00F7    | DIVISION SIGN              | division                                    | `/`         |
| U+22CF    | CURLY LOGICAL AND          | max                                         | `max`       |
| U+22CE    | CURLY LOGICAL OR           | min                                         | `min`       |
| U+2227    | LOGICAL AND                | conjunction                                 | `&&`        |
| U+2228    | LOGICAL OR                 | disjunction                                 | `||`        |
| U+00AC    | NOT SIGN                   | negation                                    | `not`       |

### Subscripts (arity suffix)

| Codepoint | Name              | Renders as | ASCII | Use            |
|-----------|-------------------|------------|-------|----------------|
| U+2082    | SUBSCRIPT TWO     | small 2    | `2`   | `coord<sub>2</sub>` -> `coord2` |
| U+2083    | SUBSCRIPT THREE   | small 3    | `3`   | `point<sub>3</sub>` -> `point3` |
| U+2084    | SUBSCRIPT FOUR    | small 4    | `4`   | `point<sub>4</sub>` -> `point4` |

### Type-set symbols (decorative; layer 9)

| Codepoint | Name                            | Common use     | ASCII alias |
|-----------|---------------------------------|----------------|-------------|
| U+2124    | DOUBLE-STRUCK CAPITAL Z         | Integer type   | `Int`       |
| U+211D    | DOUBLE-STRUCK CAPITAL R         | Real           | `Real`      |
| U+2115    | DOUBLE-STRUCK CAPITAL N         | Natural        | `Nat`       |
| U+2102    | DOUBLE-STRUCK CAPITAL C         | Complex        | `Complex`   |
| U+2208    | ELEMENT OF                      | "is a"         | `:`         |

### Greek (free identifiers)

The whole Greek block (U+0391..U+03A9 uppercase, U+03B1..U+03C9
lowercase) is fair game for identifiers. Common conventions:

| Codepoint | Letter | Typical role                   |
|-----------|--------|--------------------------------|
| U+03B1    | alpha  | a generic value                |
| U+03B2    | beta   | a second generic               |
| U+03B5    | epsilon| tolerance / small number       |
| U+03C1    | rho    | percent / ratio                |
| U+03BB    | lambda | anonymous-verb thunk variable  |
| U+03BC    | mu     | recursion combinator           |
| U+03A3    | Sigma  | sum / fold                     |
| U+03A0    | Pi     | product                        |

### Question / boolean suffix

| Codepoint | Name                          | Common use        | ASCII |
|-----------|-------------------------------|-------------------|-------|
| U+003F    | QUESTION MARK                 | bool-result suffix| `?`   |
| U+02C0    | MODIFIER LETTER GLOTTAL STOP  | bool suffix alias | `?`   |

## Conventions

- **Mint glyph first.** A name introduction always begins with
  the mint glyph (`▪`, or `*` in ASCII fallback files). The rest of the name
  may use any combination of identifier characters above.
- **Arity in the name.** Trailing subscript or ASCII digit
  encodes how many values the verb produces. `coord₂` and its folded
  internal spelling `coord2` always push 2.
- **`?` for predicates.** A name ending in `?` is conventionally
  boolean-valued. `success?`, `is_empty?`.
- **Canonical examples use glyphs.** ASCII is a fallback for tooling
  and bootstrap tests, not the language's primary presentation.

## Why a small alphabet matters

Every glyph in the minimal alphabet has to be lex-recognized.
Every additional symbol the lexer must distinguish costs a
decision. Tuplet's surface stays small (just the table at the
top of this file) and pushes everything else into either:

- ordinary identifier characters (Greek letters, mathy glyphs
  appearing inside names), or
- `TLiteral` tokens registered at `▪syntax` declaration time
  (operators in user templates).

The wider palette in this doc is **convention**, not
implementation surface. Users are encouraged to pick from it,
but the lexer doesn't care.
