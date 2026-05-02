# Tuplet -- Kernel/Prelude Boundary

Load-bearing architectural decision: **extensions should be used
for as much of the language as possible**. This document fixes the
kernel/prelude split. Every later saga rests on it.

This doc supersedes the parts of `docs/prd.md`, `docs/grammar.md`,
`docs/design.md`, and `docs/lowering.md` that imply a fixed set of
operators, control-flow keywords, or builtin verbs. After reading
this, those earlier docs are best understood as describing the
*surface user experience* once the prelude is loaded -- not the
shape of the compiler.

## Philosophy

The kernel contains only what cannot be expressed in Tuplet
itself. Every operator, every control-flow construct, every
tuple helper that *can* live in `.tup` source *must* live there.

Precedents:

- **Forth.** `forth.s` is the kernel. `IF`, `BEGIN`, `UNTIL`,
  even `VARIABLE` are immediate words: they extend the language
  while running in it. The kernel itself only ships the
  irreducible primitives (`+`, `@`, `!`, branch instructions).
- **Lisp / Scheme.** A handful of special forms (`if`, `lambda`,
  `quote`, `define`, `define-syntax`) plus macros that build
  every higher-level construct. R5RS's prelude is mostly
  `define-syntax` over those primitives.

Tuplet aims for the same shape: tiny core, large prelude,
language extension as a first-class user feature.

## Litmus test

A form belongs in the kernel only if its definition would have
to bottom out in itself or in something not yet available. If it
can be defined using earlier-declared things plus the
`prim/forth` raw escape hatch, it belongs in the prelude.

## Two extension mechanisms

Tuplet exposes two complementary ways for users to extend the
language:

### 1. Template substitution (the workhorse)

A `syntax` declaration registers a template with `_` slots and
an expansion. At parse time, when the input matches the
template, the slots are substituted into the expansion. The
expansion is itself Tuplet (or `prim/forth` escapes), so it
lowers normally.

This is how all control flow and operators are defined. It does
**not** require anonymous verbs at runtime; the substitution is a
compile-time text-tree rewrite, like Forth immediate words or
Scheme syntax-rules.

```
syntax  if _ then _ else _ end
expand  _1  prim/forth "IF"  _2  prim/forth "ELSE"  _3  prim/forth "THEN"
```

(Each `_N` reads as "the N-th slot's lowered Forth.")

### 2. Anonymous verb literals (higher-order)

For genuinely higher-order patterns -- passing a thunk as a
value, deferring evaluation, callbacks -- Tuplet provides
`{ expr }` which compiles `expr` to a colon definition and
yields its xt as a value.

```
apply(my_callback args)
my_callback <- { x + 1 }
```

This requires either `:NONAME` (preferred, ANS Forth) or
synthetic-name colon definitions (fallback). See `Risks` below.

Most prelude constructs use mechanism (1) only. Mechanism (2) is
reserved for cases where genuine deferred evaluation is needed.

## Kernel inventory

These forms are primitive. They cannot be moved to the prelude
because the prelude itself is parsed using them.

| Form                                  | Role                              | Why kernel                                                       |
|---------------------------------------|-----------------------------------|------------------------------------------------------------------|
| `▪` (ASCII fallback `*`)              | **mint operator**: introduces every new name binding | The DSL user reaches for this every time they extend the language. Cannot itself be defined in the language; it's the act of definition. |
| `▪syntax T ───‣ V` / `▪syntax T expand E` | declare new template + expansion (minted)      | Bootstraps every other declaration.                            |
| `▪NAME ───‣ ⎛...⎠ ⟵ BODY`             | mint a verb / tuple-var with body | The way to bind a name to executable code or storage.            |
| `⟵`                                  | assignment (to existing name)     | Used in every later declaration; must be hard-coded to parse them. |
| `,`                                   | value separator                   | Required by parser to delimit slots and value lists.             |
| `⎛` `⎠`                               | grouping / call delimiters        | Required by parser; grammar can't parse `syntax` without them.   |
| `{` `}` (Unicode aliases U+23A7/U+23AB) | block delimiters / anonymous verb | Group multi-statement bodies; also serve as anonymous-verb literals (`{ EXPR }` -> xt). |
| `#`                                   | line comment                      | Required so the kernel itself can be commented.                  |
| `_` (inside `▪syntax T ...`)          | template slot marker              | Has no meaning except inside `syntax`; cannot be defined later.  |
| `prim/forth "WORD"`                   | raw Forth escape                  | The bridge to the runtime; nothing the prelude calls would work without it. |
| `prim/X` namespace                    | exposed Forth primitives          | Each `prim/X` is a thin wrapper the prelude can wrap further.    |

### `prim/` namespace

The kernel exposes one `prim/X` per kernel-level Forth primitive
the prelude is allowed to wrap. Prelude code calls these and
nothing else from Forth.

| `prim/`           | Lowers to (Forth)        | Stack effect       |
|-------------------|--------------------------|--------------------|
| `prim/add`        | `+`                      | `( a b -- s )`     |
| `prim/sub`        | `-`                      | `( a b -- d )`     |
| `prim/mul`        | `*`                      | `( a b -- p )`     |
| `prim/slashmod`   | `/MOD`                   | `( a b -- q r )`   |
| `prim/less`       | `<`                      | `( a b -- f )`     |
| `prim/equal`      | `=`                      | `( a b -- f )`     |
| `prim/zequ`       | `0=`                     | `( n -- f )`       |
| `prim/dup`        | `DUP`                    | `( a -- a a )`     |
| `prim/drop`       | `DROP`                   | `( a -- )`         |
| `prim/swap`       | `SWAP`                   | `( a b -- b a )`   |
| `prim/over`       | `OVER`                   | `( a b -- a b a )` |
| `prim/store`      | `!`                      | `( v a -- )`       |
| `prim/fetch`      | `@`                      | `( a -- v )`       |
| `prim/create`     | `CREATE`                 | runtime            |
| `prim/comma`      | `,`                      | `( v -- )`         |
| `prim/emit`       | `EMIT`                   | `( c -- )`         |
| `prim/dot`        | `.`                      | `( n -- )`         |
| `prim/cr`         | `CR`                     | `( -- )`           |
| `prim/space`      | `SPACE`                  | `( -- )`           |
| `prim/tor`        | `>R`                     | `( v -- )`         |
| `prim/rfrom`      | `R>`                     | `( -- v )`         |

Anything not on this list is unreachable from the prelude --
deliberately. Adding a primitive is a kernel change.

## Prelude inventory

These move to `lib/std.tup`. Each is defined using earlier
prelude entries plus the `prim/` namespace.

| Form                                 | Depends on               | Sketch                                            |
|--------------------------------------|--------------------------|---------------------------------------------------|
| `_ + _`                              | `prim/add`               | `syntax _ + _ expand prim/add`                    |
| `_ - _`                              | `prim/sub`               | analogous                                         |
| `_ * _`                              | `prim/mul`               | analogous                                         |
| `_ < _`                              | `prim/less`              | analogous                                         |
| `_ = _`                              | `prim/equal`             | analogous                                         |
| `_ <> _`                             | `=`, `not`               | `syntax _ <> _ expand _1 _2 = not`                |
| `_ <= _`                             | `<`, `=`, `or`           | `syntax _ <= _ expand _1 _2 < _1 _2 = or`         |
| `_ >= _`                             | `<`, `=`, `or`           | swap-and-`<=` analog                              |
| `not _`                              | `prim/zequ`              | `syntax not _ expand _1 prim/zequ`                |
| `_ && _`                             | (uses `if/then/else`)    | short-circuit; loads after `if`                   |
| `_ || _`                             | `if/then/else`           | short-circuit; loads after `if`                   |
| `max _ _`                            | `prim/over`,`prim/less`,`prim/swap`,`prim/drop` | `syntax max _ _ expand _1 _2 prim/over prim/over prim/less prim/forth "IF" prim/swap prim/forth "THEN" prim/drop` |
| `min _ _`                            | analogous                | analogous                                         |
| `_ div _`                            | `prim/slashmod`          | `syntax _ div _ expand _1 _2 prim/slashmod prim/swap prim/drop` |
| `_ max2 _`                           | `prim/over`...           | analogous to `max` but no final `prim/drop`       |
| `_ min2 _`                           | analogous                | analogous                                         |
| `_ div2 _`                           | `prim/slashmod`          | `syntax _ div2 _ expand _1 _2 prim/slashmod`      |
| `if _ then _ else _ end`             | `prim/forth "IF/ELSE/THEN"` | template substitution; see worked example      |
| `while _ do _ end`                   | `prim/forth "BEGIN/UNTIL"` | analogous                                       |
| `match _ with ... end`               | `if/then/else`, `=`      | sketch in a later saga                            |
| tuple-var decl `name -> ( fs )`      | kernel `:` + `prim/create`,`prim/comma`,`prim/store`,`prim/fetch` | the prelude generates the `name!`/`name@` words shown in `docs/lowering.md`. The decl form *itself* might be a `syntax`. |
| `plot _ _ _ _`                       | `prim/dot`,`prim/cr`,`prim/tor`,`prim/rfrom` | per `docs/lowering.md`                  |

The tuple-var declaration entry deserves a note: ideally even the
`name -> (f1 f2 ...)` form is a prelude `syntax`. The bootstrap
question is whether the *kernel `:` form* alone is enough to
declare it before any `syntax` declarations exist. If yes, it's
prelude. If we need a hardcoded `name -> (...)` to even *parse*
later code, it stays kernel. Defer to `tuplet-prelude` saga;
either answer is consistent with this doc.

## Bootstrap order

The kernel loads first (it is hard-coded into the parser and
emitter). Then `lib/std.tup` is processed top to bottom. Each
declaration may reference only:

1. The kernel.
2. The `prim/` namespace.
3. Earlier declarations in `lib/std.tup`.

Suggested order in `lib/std.tup`:

1. Arithmetic operators (`+ - *`).
2. Comparisons (`< = 0=` thin wrappers; `<> <= >=` after).
3. `not`.
4. `if _ then _ else _ end`.
5. `&& ||` (need `if`).
6. `min`, `max`, `div`, `min2`, `max2`, `div2`.
7. `while _ do _ end`.
8. `match` (sketch).
9. `plot` and any other I/O verbs.
10. Tuple-var declaration sugar (if expressible).

Rule: **no forward references**. If a definition needs `X`, `X`
must already be loaded. Document this in `lib/std.tup` with a
header comment and verify in the loader.

## `syntax` semantics

### Template grammar

```
syntax-decl  ::= "syntax" template "->" verb-name
              |  "syntax" template "expand" expansion
template     ::= ( literal-token | "_" )+
expansion    ::= ( token | "_" digit )*
literal-token::= identifier | symbol           # not "_", not reserved
```

- `_` in the template marks a slot.
- `_1`, `_2`, ... in the expansion reference slots positionally.
- Literal tokens in the template become reserved on registration.
- The first form (`-> verb`) means the template lowers to a call
  to `verb`, with each slot becoming an argument; the second form
  (`expand <expansion>`) inserts the expansion textually.

### Slot evaluation

For `expand`-form templates, each slot is **lowered in place**:
the slot's expression is compiled to its IR/Forth, and that IR is
substituted at the `_N` position in the expansion. No thunking;
no xts. Slots are unconditionally evaluated unless the expansion
arranges otherwise (e.g. `if/then/else` uses the literal Forth
`IF/ELSE/THEN` to skip the unwanted branch at *runtime*).

For `-> verb`-form templates, each slot is wrapped as `{ ... }`
(an anonymous verb literal) and its xt is passed as a value.
Anonymous verbs lower to kernel `:NONAME ... ;` (available since
`sw-embed/sw-cor24-forth#5`); this is the path for higher-order
user code.

### Matching policy

- Longest-match wins.
- On ties: first-declared wins.
- Literal tokens used in active templates are reserved
  identifiers; binding a variable named `if` after `if/then/else`
  is registered is a compile error.

This is a PoC compromise. A real solution needs precedence levels
(Agda-style); document this as a known limitation.

## Worked example: `if/then/else`

### Prelude source (`lib/std.tup`)

```
# Control flow: if/then/else. The `*` mints the new syntax form.
*syntax if _ then _ else _ end expand
  _1  prim/forth "IF"  _2  prim/forth "ELSE"  _3  prim/forth "THEN"
```

### Use site

```
result <- if x > 0 then 1 else 0 - 1 end
```

### After template expansion (still in IR)

```
ILoad      "x"
IPushInt   0
IBinOp     OpLess         # from prelude: _ < _ -> prim/less
IPushInt   0
IBinOp     OpEqual
... [details: actual lowering of `x > 0` is `x 0 < 0=` for sw-cor24-forth's `<`]
IPrimForth "IF"
IPushInt   1
IPrimForth "ELSE"
IPushInt   0
IPushInt   1
IBinOp     OpSub
IPrimForth "THEN"
IStore     "result"
```

(`IPrimForth` is a new IR opcode the kernel adds: emits a literal
Forth token, no stack effect known to the IR.)

### Lowered Forth

```forth
x@                  \ ILoad x
0 <                 \ x > 0  (note: > is `< 0=` swapped; details in lowering)
IF
  1                 \ then-branch
ELSE
  0 1 -             \ else-branch  (-1)
THEN
result!             \ IStore result
```

`IF/ELSE/THEN` are the kernel Forth words, as they always were.
The Tuplet emitter never special-cased control flow -- the
prelude `syntax` declaration did.

## Implications for the saga arc

The previously planned **seven** sagas become **eight**.

| # | Saga                  | One-line goal                                                                       |
|---|-----------------------|-------------------------------------------------------------------------------------|
| 1 | `tuplet-lexer`        | tokenize `.tup` source, including template-literal tokens fed back from the parser. |
| 2 | `tuplet-parser`       | parse tuple-shaped statements; maintain the `syntax` registry; longest-match template matcher. |
| 3 | `tuplet-checker`      | tuple/arity-check against the registry. No hardcoded operator list.                 |
| 4 | `tuplet-ir`           | lower AST to stack IR including `IPrimForth` opcodes; thunk-build for `{...}`.      |
| 5 | `tuplet-interp`       | minimal reference interpreter over IR.                                              |
| 6 | `tuplet-forth-emit`   | emit Forth from IR; `IPrimForth` -> literal token; `{...}` -> synthetic-name `:`.   |
| 7 | **`tuplet-prelude`**  | write `lib/std.tup`; prove the bootstrap by defining all operators + control flow.  |
| 8 | `tuplet-demos`        | every demo uses prelude features only; `if/while/match` defined in `.tup`.          |

Reshapes from prior plan:

- `tuplet-parser` no longer parses a fixed grammar. The kernel
  forms (`syntax`, `:`, `<-`, `,`, `()`, `#`, `_`, `{}`,
  `prim/forth`) are hardcoded; everything else flows from the
  registry built up by `syntax` declarations.
- Parser AST work is tuple-first: signatures, tuple values, and
  assignment patterns preserve shape and field names so later
  checker/lowering stages can treat functions as tuple transforms.
- `tuplet-checker` does not know what `+` or `if` are. It asks
  the registry.
- `tuplet-prelude` is an explicit phase whose exit criterion is
  "every operator and control-flow construct documented in the
  PRD parses and runs, defined in `.tup`."
- `tuplet-demos` exit criterion is sharpened: a regression test
  that *removes* `lib/std.tup` and verifies the demos no longer
  parse, proving the prelude is load-bearing.

## Risks and unknowns

- **Parser cost up front.** The OCaml-subset parser must support
  template registration and longest-match matching from day one.
  A fixed-grammar parser is not a stepping stone; would have to
  be rewritten. Plan for `sw-cor24-ocaml` to reveal real gaps
  (efficient string compare, mutable maps); file upstream issues
  if encountered.
- **~~`:NONAME` absent.~~ Resolved.**
  `sw-embed/sw-cor24-forth#5` is closed (commit `ff7b43d`);
  `:NONAME ( -- xt )` is now a kernel primitive. Anonymous verbs
  in mechanism (2) lower directly to `:NONAME ... ;`; the
  synthetic-name fallback is no longer needed. Verified locally
  via reg-rs baseline `tuplet_forth_noname_smoke`.
- **Mixfix ambiguity.** Longest-match + first-declared-wins is a
  PoC compromise. Real solution needs precedence levels per
  template. Defer.
- **No hygiene.** Templates can capture user-bound names. Punt
  to "no hygiene; document in the prelude" for the PoC.
- **Bootstrap fragility.** Reordering entries in `lib/std.tup`
  can silently break loading. Add a build-time check that
  forward references fail loudly.
- **"Mostly in itself" is a spectrum.** Forth is ~30%
  self-defined initially, Scheme prelude ~70%, full self-hosting
  (parser written in Tuplet) is a separate larger effort. PoC
  target: ~50% -- all operators, all control flow, all tuple
  helpers in `.tup`; parser stays in OCaml.

## Note for the next step (`phased-plan`)

The pending step `phased-plan` (now at saga position 9) has a
prompt that predates this architecture decision. When it runs,
the agent must:

1. Treat **this kernel doc as the source of truth**, not the
   stale prompt.
2. Write `docs/plan.md` enumerating **eight** sagas (per the
   table above), not seven.
3. Open `docs/plan.md` with a one-line callout pointing readers
   to `docs/kernel.md` for the architecture this plan implements.
4. Use the same per-saga shape the stale prompt requested
   (Goal, Entrance criteria, Exit criteria, Key deliverables,
   Primary risks); only the saga count and the parser/checker
   reshapes are different.

If the agent encounters a contradiction between the stale prompt
and this kernel doc, this kernel doc wins.
