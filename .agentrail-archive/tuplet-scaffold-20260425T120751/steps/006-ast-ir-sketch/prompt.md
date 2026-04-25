# Step: ast-ir-sketch

Write `docs/design.md` -- the low-level design for Tuplet's AST and
stack IR, drawing on `docs/research.txt` lines ~2860-3050 and on
`docs/grammar.md`.

## Required sections

1. **Pipeline diagram** -- text-only box/arrow sketch:
   source -> lexer -> parser -> AST -> name resolution -> arity
   checker -> stack IR -> backend (interpreter / Forth emitter).

2. **AST types** -- OCaml-subset types compatible with what
   `sw-cor24-ocaml` supports today (ints, bools, strings, lists,
   pairs, options, sum-ish types via tagged tuples if needed;
   pattern matching). Include at minimum:
   - `name = string`
   - `op` variants for `+ - * max min div max2 min2 div2`
   - `expr` variants for `EName | EInt | EBool | EPct | EName |
     EBinary | ECall | ETuple`
   - `pattern` for LHS: `PName of name | PTuple of name list`
   - `stmt` for `SAssign | SExpr | SDecl | SSignature | SComment`
   - a record/tagged-tuple shape for declarations and signatures
     that carries field names + arities.

   Note any cases where the OCaml subset forces a workaround
   (e.g., no real records -- emulated with tagged tuples). If
   something is genuinely missing from the interpreter, flag it
   as a candidate upstream issue, do not pretend the feature
   exists.

3. **Stack IR** -- instruction set per `research.txt` ~3010-3022,
   adapted for the PoC:
   - `IPushInt of int`
   - `IPushBool of bool`
   - `IPushPct of int`          (percent as integer 0..100)
   - `IPushSymbol of string`    (for names like `Red`)
   - `ILoad of name`            (scalar load)
   - `IStore of name`
   - `ILoadTuple of name * int` (load N values for a tuple var)
   - `IStoreTuple of name * int`
   - `ICall of name * int`      (call with N inputs from stack)
   - `IBinOp of op`
   Document the stack effect of each.

4. **Builtin verb registry** -- a small table of builtins the
   PoC ships with: `plot (x y color c?) -> (success?)`, `max2`,
   `min2`, `div2`, arithmetic ops. Give each a row:
   name, input arity, output arity, notes.

5. **Worked example** -- show the translation of one program
   end-to-end:
   ```
   coord2 -> (x y)
   coord2 <- 3, 9
   success? <- plot(coord2 Red 50%)
   ```
   as AST (pseudo-OCaml), then as stack IR (linear list of
   instructions), then as expected Forth output (mirrors the
   lowering doc that comes next).

## Style

- ASCII-only (`markdown-checker -f docs/design.md`).
- Under ~300 lines.
- Use fenced code blocks for AST, IR, and Forth snippets.
- Short paragraphs; bullet lists welcome.

## Do not

- Do not implement a lexer or parser yet.
- Do not edit outside this repo.
- Do not introduce typing / HM inference.

## If blocked

- If the OCaml subset provably cannot represent something needed
  (e.g., mutable hashtable, deeply nested records), file
  `sw-embed/sw-cor24-ocaml` issue and note it in the design doc
  under an "Upstream dependencies" section. Do not change this
  repo's approach to work around -- flag and pause.

## Finish

- Commit code + full .agentrail/ delta + push.
- `agentrail complete --summary "drafted docs/design.md with AST,
  stack IR, and worked example" --reward 1 --actions "synthesized
  research notes into a typed-AST/IR design"`.

## Suggested next step

Propose `forth-lowering-rules`: write `docs/lowering.md` covering
how each IR instruction and each surface construct (tuple decl,
destructuring assignment, call-with-splice, binary op) lowers to
specific Forth words, including the runtime words the PoC assumes
(CREATE, VARIABLE, : ;). Include a cross-reference to the
instructions available in `sw-cor24-forth/forth.s`.
