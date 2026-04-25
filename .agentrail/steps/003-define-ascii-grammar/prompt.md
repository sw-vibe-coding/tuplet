# Step: define-ascii-grammar

Write `docs/grammar.md` — the Tuplet surface grammar, with ASCII as
the primary syntax and Unicode aliases noted.

## Required content

1. **Lexical rules** — identifiers (including trailing digits for
   arity, e.g. `coord2`, `point4`), integer literals, percent
   literals (`50%`), comma, parens `(` `)`, assignment `<-` (Unicode
   `⟵`), mapping `->` (Unicode `───‣`), binary operator tokens, line
   comments.
2. **Unicode table** — short table mapping ASCII alternatives to the
   Unicode glyphs used in `docs/research.txt`:
   - `<-` / `⟵`
   - `->` / `───‣`
   - `(` `)` / `⎛` `⎠`
   - `max2` / `⋏₂`, `min2` / `⋎₂`, `div2` / `÷₂`
   - arity subscript `2` / `₂`
3. **Grammar** — EBNF or similar for:
   - program: sequence of statements
   - statement: declaration | assignment | expression | signature
   - declaration: typed tuple variable mint, e.g. `coord2 -> (x y)`
     or with init `coord2 -> (x y) <- 3, 9`
   - assignment: `<lvalue> <- <expr>` where lvalue is one or a
     comma-separated list of names
   - expression: literal | name | binary-op | call
   - call: `name(args)` where args are space-separated values
     (a tuple variable contributes its arity at call site)
   - signature: `name(inputs) -> (outputs)`
4. **Arity rules** — bullet list. A tuple variable named with
   trailing digit N produces N values. `maxN`, `minN`, `divN` are
   shorthand for the N-output variants. Assignment arity on the LHS
   must match the RHS arity. Call input arity must match the verb's
   declared input arity after splicing.
5. **Splicing** — default policy: in call position, a tuple variable
   splices its values. (Document this explicitly; note the open
   question of how to pass a tuple as a single value — leave as a
   TODO for a later spec.)
6. **Valid and invalid programs** — 4 of each with one-line reason
   why.
7. **File extension** — `.tup`.

## Style

- ASCII-only; `markdown-checker -f docs/grammar.md` should pass.
- Under ~250 lines.
- Prefer short fenced code blocks of ASCII Tuplet over prose
  explanations.

## Reference

- `docs/research.txt` lines ~3470–3540 for the ASCII fallback sketch
  and CLI naming.
- `docs/prd.md` (written in the previous step) for the core
  concepts.

## Do not

- Do not implement a lexer or parser yet.
- Do not edit outside this repo.

## Finish

- Commit, then `agentrail complete --summary "wrote ASCII grammar
  for Tuplet" --reward 1 --actions "drafted EBNF and Unicode
  aliases"`.
