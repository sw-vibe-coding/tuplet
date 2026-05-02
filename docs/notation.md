# Tuplet Canonical Notation

This file is the local source of truth for Tuplet surface notation.
Older docs in this and sibling repos may still show ASCII-first or
experimental glyphs. Treat those as stale until rewritten against this
table.

## Core Glyphs

| Role | Canonical | ASCII fallback | Internal token |
|---|---|---|---|
| Mint / introduce binding | `▪` | `*` | `MINT` |
| Assignment / store | `⟵` | `<-` | `LARROW` |
| Signature / mapping | `───‣` | `->` | `RARROW` |
| Tuple/call open | `⎛` | `(` | `LPAREN` |
| Tuple/call close | `⎠` | `)` | `RPAREN` |
| Action/operator open | `❪` | `(` for now | deferred |
| Action/operator close | `❫` | `)` for now | deferred |
| Arity suffix two | `₂` | `2` | folded into identifier |
| Type ascription | `ː` | `:` | deferred |
| Integer type | `ℤ` | `Int` | deferred |
| Approx equal | `≈` | none settled | prelude syntax |
| Plus/minus tolerance | `±` | none settled | prelude syntax |
| Percent | `%` | `%` | `PCT` |

The filled square `▪` is the mint glyph. `•` is not mint. `*` is only
an ASCII fallback and should not be used in canonical examples except
when a file is explicitly testing fallback input.

## Canonical Examples

```tuplet
▪coord₂ ───‣ ⎛x y⎠
coord₂ ⟵ 3 , 9
a , b ⟵ coord₂
```

```tuplet
if α ≈ β ± ρ % then
   X
else
   Y

a ≈ b ± p %
```

```tuplet
                                      ╭
                                      ┊ 1 ⟶
▪ Power ⎛nːℤ  eːℤ⎠ ───‣ ⎛pːℤ⎠ ⟵ loop e times     iff e is positive
                                      ┊    n ❪×❫⟶
                                      ╰
```

## Implementation Policy

The implementation may normalize canonical glyphs to ASCII-like
internal token names (`MINT`, `LARROW`, `RARROW`, `LPAREN`, `RPAREN`)
for dumps and tests. Source-facing docs, demos, and new fixtures should
use canonical notation first and label ASCII fallback examples
explicitly.

Current known gaps:

- `⎛` and `⎠` are documented canonical tuple/call delimiters, but the
  current lexer/parser still primarily exercise ASCII `(` and `)`.
- `₂` should fold into identifier arity, but existing implementation
  mostly uses ASCII `2`.
- `ːℤ`, `❪×❫`, `≈`, and `±` are not implemented yet.
