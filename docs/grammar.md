# Tuplet -- Surface Grammar

This document specifies the Tuplet surface syntax. ASCII is the
primary form; a small Unicode alias table is given for authoring in
the research notation.

## File extension

`.tup`

## Lexical rules

- **Whitespace.** Spaces and tabs separate tokens. Line breaks
  terminate statements (see Grammar).
- **Comments.** `#` starts a line comment; the rest of the line is
  ignored.
- **Identifiers (names).** Start with an ASCII letter, followed by
  any combination of letters, digits, or `_`. May end with `?`.
  Trailing digits are significant: they declare arity for tuple-
  producing names (see Arity rules). Examples: `coord2`, `point4`,
  `x`, `success?`, `Red`.
- **Integer literals.** Optional leading `-`, one or more digits.
  Examples: `0`, `42`, `-7`.
- **Percent literals.** An integer literal immediately followed by
  `%`. Examples: `50%`, `100%`.
- **Punctuation.** `,` `(` `)`
- **Mint operator.** Canonical Unicode: `BULLET` (U+2022).
  Aliases also recognized by the lexer: `BLACK SMALL
  SQUARE` (U+25AA). ASCII fallback **proposed `*`**
  (small filled mark; needs user confirmation -- alternatives:
  `!`, `mint `, `def `). The mint operator must precede every
  NEW name binding: tuple-var declaration, verb signature,
  user-defined verb body, `syntax` declaration. Example:
  `*coord2 -> (x y)` mints the tuple variable; subsequent
  `coord2 <- 3, 9` is an ordinary assignment. Without the mint
  operator, references to unbound names are errors. This is
  the construct the DSL user reaches for whenever they want
  to extend the language.
- **Assignment.** `<-`
- **Mapping (signature arrow).** `->`
- **Binary operators.** Symbolic: `+`, `-`, `*` (caveat: `*` may
  alias the mint operator depending on the chosen ASCII fallback;
  context-sensitive lexing or a different fallback resolves it).
  Named: `max`, `min`, `div`, `max2`, `min2`, `div2`. Named
  operators follow identifier rules lexically.

## Unicode aliases

Accepted by the lexer as exact synonyms for their ASCII forms:

| ASCII  | Unicode |
|--------|---------|
| `*` (TBD) | mint operator: BULLET (U+2022) -- also accepts BLACK SMALL SQUARE (U+25AA) |
| `<-`   | LEFTWARDS ARROW         (U+27F5 or U+2190) |
| `->`   | heavy mapping arrow     (U+2500 x3 + U+2023) |
| `(`    | shell-bracket left      (U+239B or U+2983) |
| `)`    | shell-bracket right     (U+239E or U+2984) |
| `{`    | LEFT CURLY BRACKET UPPER HOOK  (U+23A7) -- block start (TBD) |
| `}`    | RIGHT CURLY BRACKET UPPER HOOK (U+23AB) -- block end (TBD)   |
| `max`  | wedge up                (U+22CF) |
| `min`  | wedge down              (U+22CE) |
| `max2` | wedge up + subscript 2  (U+22CF U+2082) |
| `min2` | wedge down + subscript 2 (U+22CE U+2082) |
| `div`  | division sign           (U+00F7) |
| `div2` | division sign + sub 2   (U+00F7 U+2082) |
| `?`    | superscript question    (U+02C0) |
| `2`    | subscript 2             (U+2082) -- arity suffix |

The lexer must fold Unicode aliases to their ASCII spelling before
the parser sees them. ASCII stays canonical in diagnostics.

## Grammar (EBNF)

```
program      ::= { statement NEWLINE }
statement    ::= comment
               | declaration
               | signature
               | assignment
               | expression

comment      ::= "#" { any-char }

declaration  ::= mint name "->" "(" field-list ")" [ "<-" expr-list ]
field-list   ::= name { name }

signature    ::= mint name "(" [ field-list ] ")" "->" "(" field-list ")" [ "<-" expr ]
mint         ::= "*" | "U+2022" | "U+25AA"   (* mint operator *)

assignment   ::= lvalue "<-" expr
lvalue       ::= name { "," name }

expression   ::= expr
expr         ::= primary
               | expr bin-op expr
               | call

call         ::= name "(" { arg } ")"
arg          ::= primary

expr-list    ::= expr { "," expr }

primary      ::= int-lit
               | pct-lit
               | name
               | "(" expr ")"

bin-op       ::= "+" | "-" | "*"
               | "max" | "min" | "div"
               | "max2" | "min2" | "div2"
```

### Statement separation

One statement per line. Blank lines are ignored. A statement may
not span multiple lines in the PoC; this simplifies the lexer.

### Precedence and associativity

For the PoC, all binary operators share one precedence level and
are left-associative. Use parentheses to disambiguate. A typing /
precedence pass is deferred.

## Arity rules

- Every expression has a static output arity (an integer >= 0).
- Integer and percent literals have arity 1.
- A bare name referring to a scalar has arity 1.
- A name whose last character run is digits declares a tuple-var
  of that arity (`coord2` -> 2, `point4` -> 4).
- `maxN`, `minN`, `divN` are multi-output operators of arity N.
  `max`, `min`, `div` with no suffix are arity 1.
- In a binary expression `a OP b`, the expression's arity is the
  operator's output arity.
- In a call `f(args)`, the call's arity is `f`'s declared output
  arity. The sum of each arg's arity (with splicing) must equal
  `f`'s declared input arity.
- In an assignment `lvalue <- expr`, the number of names on the
  LHS must equal the output arity of the RHS.
- In a declaration `name -> (f1 f2 ... fN)`, the name's arity is
  N. The declared field names are documentation; they do not
  introduce new bindings outside the declaration.

## Splicing

**Default policy.** In call position, every argument contributes
its full arity to the callee's input list. Tuple variables always
splice.

Example:

```
success <- plot(coord2 Red 50%)
# coord2 -> 2 values, Red -> 1, 50% -> 1; plot expects 4.
```

**Open question (TODO).** There is no current syntax to pass a
tuple as a single boxed value. Candidates discussed in
`docs/research.txt`:

- an explicit box marker, e.g. `plot(box(coord2) Red 50%)`,
- a no-splice unary operator, e.g. `plot(@coord2 Red 50%)`.

Defer to a later spec saga. No splicing control is implemented
in the PoC.

## Valid programs

```
# 1. Tuple init + destructuring.
*coord2 -> (x y)        # mint the tuple variable
coord2 <- 3, 9          # ordinary assignment to existing
a, b <- coord2          # destructure
```

```
# 2. Multi-output operator.
q, r <- 3 max2 5        # q=5, r=3
```

```
# 3. Integer + fractional parts.
integer, fractional <- 7 div2 3
```

```
# 4. Call-site splice.
*plot(x y color transparency) -> (success?)   # mint verb signature
*coord2 -> (x y)                               # mint tuple var
coord2 <- 3, 9
success? <- plot(coord2 Red 50%)
```

```
# 5. User-defined verb (mint with body).
*add(a b) -> (sum) <- a + b
n <- add(2 3)            # n = 5
```

```
# 6. Mint a syntax extension (the heart of the PoC).
*syntax do _ while _ end expand
  prim/forth "BEGIN" _1 _2 prim/forth "UNTIL"
```

## Invalid programs

```
# 1. Arity mismatch on assignment LHS.
q <- a max2 b           # RHS arity 2, LHS arity 1
```

```
# 2. Too few arguments to call after splicing.
plot(coord2 Red)        # arity 2 + 1 = 3, plot needs 4
```

```
# 3. Tuple var mint with wrong field count for name arity.
*coord2 -> (x y z)      # name declares arity 2, fields list has 3
```

```
# 5. Missing mint operator on first declaration.
coord2 -> (x y)         # `coord2` not yet bound; mint required
```

```
# 4. Line-spanning statement.
coord2 <- 3,
         9              # statements don't span lines in the PoC
```
