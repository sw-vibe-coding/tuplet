# Tuplet Language Wishlist

A design playground: the layered preludes, power features, and
ergonomics that take Tuplet beyond Turing-completeness toward
being a useful programming language. Everything here is user-
extensible via the `*syntax T expand E` mechanism (the kernel's
single load-bearing primitive); nothing requires changing the
compiler or runtime.

This document is **research and aspiration**, not a
specification. It complements `docs/poc-goals.md` (what the
PoC ships) and `docs/kernel.md` (the irreducible core). The PoC
proves the mechanism with `do..while`; this doc charts what
gets built on that mechanism after.

Out of scope for this entire wishlist: memory limits, execution
speed, GC, optimization, TCO. A future Tuplet successor can
revisit those; this PoC's job is to show the mechanism scales
in expressive power.

## Vision

A small kernel + a tower of `*syntax` declarations that the
user can extend, replace, or compose at any level. Forth's
"the language is its own metalanguage" plus Lisp's
"everything is a macro" -- but with infix readability and
stack-effect-aware multi-output verbs from the start.

Specifically: the user types `*syntax do _ while _ end expand
...` to add `do..while`, and that line is the same kind of
thing the prelude author types to add `if..then..else`,
`match..with`, modules, error handling, type annotations,
pipelines, etc. There is no privileged second class of
language designer.

## Design philosophy

1. **Mint or be missing.** Every name and every syntactic
   form must be introduced by `*` (mint). No name appears
   "for free." This makes the language's working surface
   explicit and inspectable.
2. **Layered preludes.** The standard library is a tower:
   each layer assumes only earlier layers + the kernel. A
   user can replace any layer (or stop at any layer for a
   constrained DSL).
3. **Multiple-output is first-class.** Verbs return tuples,
   destructuring is natural, splicing at call sites is the
   default. No need to overload.
4. **Errors are values OR effects, user's choice.** The
   prelude offers both `Result`-style values and `try/catch`-
   style effects, and both are minted with the same
   `*syntax` mechanism.
5. **Modules are just namespaces.** A module is a region of
   bindings; the runtime doesn't need to know.

## Layered preludes

| Layer | Name              | What it adds                                       | Depends on    |
|-------|-------------------|----------------------------------------------------|---------------|
| 0     | kernel            | `*`, `<-`, `,`, `()`, `{}`, `#`, `_`, `*syntax`, `prim/`  | (the host) |
| 1     | core-control      | `if/then/else/end`, `do/while/end`, `not`, `&&`, `||` | 0 |
| 2     | core-arith        | `+ - * /`, `<`, `<=`, `>=`, `=`, `<>`, `max`, `min`, `div`, `max2`, `min2`, `div2` | 0, 1 |
| 3     | data              | `Pair`, `List` (cons, hd, tl, length, map, ...), `Option` (`Some`, `None`)  | 0, 1, 2 |
| 4     | result-and-assert | `Result` (`Ok`, `Err`), `assert`, `panic`, `try _ catch _ end` | 0, 1, 3 |
| 5     | modules           | `*module Foo .. end`, `Foo.bar` qualified access, `*open Foo` | 0 |
| 6     | pipelines         | `_ |> _`, `_ |>> _` (curry), `_ ; _` sequence       | 0, 1, 2 |
| 7     | match-with        | full pattern matching as a `*syntax` -- including ADT cases | 0, 1, 3 |
| 8     | adt-records       | `*type Foo = Bar | Baz of int`, record minting     | 0, 1, 7 |
| 9     | type-annotations  | `: Int`, `: List<Int>` -- decorative; no enforcement at PoC | 0 |
| 10    | math-style        | tail conditionals (`_ if _ else _`), curried defs (`*name a b := body`), `:=`, approx-equal, plus-minus, geq, math glyphs | 0, 1, 2 |
| 11    | testing           | `_ ->> _` test-arrow, `_ should _`, `*test name { ... }`  | 0, 4 |
| 12    | board-io          | `set_led`, `read_switch`, `getc`, `putc`, `print`, `read_line` | 0 |

A given Tuplet program loads layers up to whatever it needs.
Embedded programs might stop at layer 4. A teaching language
might stop at layer 7. A "full" Tuplet is everything.

## Sketches per layer

### Layer 1: core-control

```
# Two-armed conditional. Slot 1 is the cond; 2 is then; 3 is else.
*syntax if _ then _ else _ end expand
  _1 prim/forth "IF" _2 prim/forth "ELSE" _3 prim/forth "THEN"

# One-armed: no else, default value 0.
*syntax if _ then _ end expand
  _1 prim/forth "IF" _2 prim/forth "ELSE" 0 prim/forth "THEN"

# Bottom-tested loop (the PoC demo).
*syntax do _ while _ end expand
  prim/forth "BEGIN" _1 _2 prim/forth "0= UNTIL"

# Pre-tested loop.
*syntax while _ do _ end expand
  prim/forth "BEGIN" _1 prim/forth "WHILE" _2 prim/forth "REPEAT"

# Logical operators (short-circuit).
*syntax not _ expand          _1 prim/forth "0="
*syntax _ && _ expand         _1 prim/forth "IF" _2 prim/forth "ELSE 0 THEN"
*syntax _ || _ expand         _1 prim/forth "IF -1 ELSE" _2 prim/forth "THEN"
```

### Layer 4: result-and-assert

```
# Assertion: prim/forth "ABORT" exits to the runtime QUIT loop.
*syntax assert _ expand
  _1 prim/forth "0= IF ABORT THEN"

# Tagged constructors mintable directly.
*Ok x  := ( 1 , x )       # arity 2 tuple: tag=1, value
*Err m := ( 0 , m )       # arity 2 tuple: tag=0, message

# Try/catch via the runtime's CATCH/THROW (Forth ANS standard
# words; if absent in the kernel, file as upstream).
*syntax try _ catch _ end expand
  _1 prim/forth "CATCH" prim/forth "?DUP IF" _2 prim/forth "THEN"

# Match a Result.
*syntax handle _ ok _ err _ end expand
  _1 prim/forth "DUP 0= IF DROP" _2 prim/forth "ELSE" _3 prim/forth "THEN"
```

### Layer 5: modules

```
# A module is a named region of bindings. Names declared inside
# get rewritten Foo.bar by the parser. Open imports the names.
*syntax module _ _ end expand
  *namespace _1
  _2
  *endnamespace

# Cross-file: each .tup file is its own module by filename.
# math.tup -> Math; calls write Math.add the way the OCaml host
# does.

# Open brings names into scope.
*syntax open _ expand
  *use_namespace _1
```

The `*namespace` and `*use_namespace` are kernel-level
extensions that the parser recognizes. They are the **only**
modules-related kernel form; everything else (aliases, nested
modules, qualified access syntax) is library on top.

### Layer 6: pipelines

```
# Forward pipe: x |> f is f x. Uses an anonymous verb to
# preserve evaluation order.
*syntax _ |> _ expand          _1 _2

# Curry a binary verb: _ |>> f g  is  fun x -> f (g x).
# Mintable but more involved; sketch only.
```

### Layer 7: match-with

A full match-with is `*syntax match _ with PAT_1 -> EXPR_1 |
PAT_2 -> EXPR_2 | ... end`. The pattern grammar is itself a
sub-language minted via further `*syntax` declarations: each
PAT is a thing, and the whole "match arm" is another mintable
form. Sketch:

```
*syntax match _ with _ end expand
  _1 prim/forth "DUP" _2

# Each arm:  PAT -> EXPR  becomes  test-pat IF expr ELSE _next THEN
*syntax _ -> _ | _ expand
  prim/forth "DUP" _1 prim/forth "= IF DROP" _2 prim/forth "ELSE" _3 prim/forth "THEN"

*syntax _ -> _ end expand
  prim/forth "DUP" _1 prim/forth "= IF DROP" _2 prim/forth "ELSE DROP THEN"
```

(Real implementation needs ADT pattern matching, which
involves discriminating tagged constructors; sketched in
layer 8.)

### Layer 8: adt-records

```
# An ADT declaration mints constructors. Each constructor is
# itself a mint statement.
*type Color = Red | Green | Blue

# Expands to:
*Red   := 0
*Green := 1
*Blue  := 2

# A constructor with payload mints a tuple-creating verb:
*type Result = Ok of any | Err of string

# Expands to:
*Ok value  := ( 1 , value )
*Err msg   := ( 0 , msg )

# Records mint a tuple constructor + accessor verbs:
*record Point ( x y )

# Expands to:
*Point x y := ( x , y )
*x_of p    := fst p
*y_of p    := snd p
```

`*type` and `*record` are themselves `*syntax` declarations;
the parser sees them as ordinary mints with the standard
`*syntax T expand E` rule. The expansions just happen to mint
multiple new names per declaration.

### Layer 10: math-style

```
# Tail conditional: math style.
*syntax _ if _ else _ expand
  _2 prim/forth "IF" _1 prim/forth "ELSE" _3 prim/forth "THEN"

# Curried definition: *Power N E := body
# Equivalent to *Power(N E) -> (P) <- body, but lighter-weight.
*syntax := _ expand <- _

# Glyph aliases (ASCII forms; the lexer also folds Unicode).
*syntax _ approx _    expand    _1 _2 -    abs       # ASCII for U+2248
*syntax _ geq _       expand    _1 _2 <    not       # ASCII for U+2265
*syntax _ leq _       expand    _1 _2 >    not       # ASCII for U+2264
*syntax _ +/- _       expand    ( _1 , _2 )          # ASCII for U+00B1; tolerance pair
```

### Layer 11: testing

```
# Test arrow: assert that LHS evaluates to RHS.
*syntax _ ->> _ expand
  _1 _2 = assert

# Named test:
*syntax test _ { _ } expand
  print _1 print " ... " _2 print " OK\n"
```

## Power features beyond Turing-completeness

| Feature                       | Mintable?   | How                                                    |
|-------------------------------|-------------|--------------------------------------------------------|
| Higher-order verbs            | yes         | `{...}` anonymous-verb literal yields an xt; pass it.  |
| Lazy evaluation               | yes         | `{...}` thunks; force via `EXECUTE`.                   |
| Recursion                     | yes         | `*name a b := ... name (a-1) b ...` self-reference.    |
| Algebraic data types          | yes         | Layer 8 sketch; tagged tuples via `*type`.             |
| Pattern matching              | yes         | Layer 7 sketch.                                        |
| Modules / namespaces          | yes         | Layer 5; one kernel hook for namespace bookkeeping.    |
| Error handling (values)       | yes         | Layer 4 `Result`.                                      |
| Error handling (effects)      | yes         | Layer 4 `try/catch` via Forth `CATCH`/`THROW`.         |
| Tail-call optimization        | runtime     | Forth tail-call is a runtime concern, not a syntax.    |
| First-class continuations     | runtime     | Needs runtime stack-saving; deferred to a successor.   |
| Type system (static)          | partial     | Layer 9 annotations are decorative; checker ignores.   |
| Hygiene                       | no          | Templates capture names; documented limitation.        |
| Automatic differentiation     | yes         | Mintable as `*syntax grad _` over arithmetic.          |
| Dependent types               | no          | Out of scope; would require a real type system.        |

The bottom four are the boundary -- anything below is a
research project, not a wishlist item.

## Error handling: how to mint it

Two complementary models, both available:

### Model A: Result type (values-as-errors)

```
# 1. Mint the constructors.
*Ok x  := ( 1 , x )
*Err m := ( 0 , m )

# 2. A divide that returns Result instead of trapping.
*safe_div n d := if d = 0 then Err "div by zero" else Ok (n div d) end

# 3. Pattern-match the result at the call site.
*r := safe_div 10 0
match r with
  Ok n  -> print "got: " print_int n
  Err m -> print "error: " print m
end
```

Pros: pure (no jumps), composes well, explicit control flow.
Cons: every callsite has to handle both arms.

### Model B: try/catch with abort

```
# 1. Use prim/forth "ABORT" or "THROW" to bail out.
*assert cond := if not cond then prim/forth "1 THROW" end
*panic msg   := prim/forth "2 THROW"

# 2. Wrap in try/catch.
try
  assert (n > 0)
  print "n is positive: " print_int n
catch
  print "n was nonpositive"
end
```

Pros: ergonomic for "just don't continue if X fails."
Cons: jumps; harder to reason about; relies on Forth `THROW`/`CATCH`.

The prelude offers both. Convention: library code uses Result
(composable); top-level scripts use try/catch (terse).

**Forth `THROW`/`CATCH`** must exist in the kernel. If absent
in `sw-cor24-forth`, file an upstream issue rather than
emulate.

## Modules: how to scale up

Three increments:

### Tier 1: file-as-module (per OCaml host's MVP)

`math.tup` -> module `Math`; calls write `Math.add`. Same
naming convention as the OCaml host. All top-level `*name`
declarations in `math.tup` become `Math.name`.

### Tier 2: in-source modules

```
*module Geom ( ... statements ... ) end
*module Color ( ... statements ... ) end

# Use:
let p := Geom.Point 3 4
let c := Color.Red
```

`*module Foo (...)` is library, not kernel: it expands to a
sequence of mints with each name prefixed by `Foo.`.

### Tier 3: aliases / open

```
*open Geom                # bring all Geom.* into the local namespace
*alias Pt = Geom.Point    # short-name a single binding
```

All three tiers are mintable; tier 1 is the only one the
parser needs explicit support for (filename-derived module
context).

## Open questions

1. **Hygiene.** A user template that internally binds `tmp`
   captures a user variable also named `tmp`. PoC accepts this
   limitation; document the consequence. Real languages
   (Scheme, Rust) solve via gensym + renaming. Mintable in
   principle but invasive to bootstrap.
2. **Mixfix precedence.** Longest-match is good enough for the
   PoC. Real precedence levels (Agda style) would let users
   declare e.g. `_ + _ at-level 4` and have the parser pick
   correctly. Out of scope.
3. **`:=` vs `<-`.** Currently treating them as synonyms in
   the wishlist. Could be distinguished: `<-` is "store now,"
   `:=` is "bind name to expression / verb body
   (definitional)." Tradeoff: clarity vs. one extra rule.
4. **Boolean truthiness.** Forth uses `0`/`-1`. Tuplet
   prelude: any nonzero truthy? Strict `-1` only? Pick before
   layer 1 ships.
5. **Test-arrow vs assertion.** `_ ->> _` is a unit-test
   assertion vs. an inline assertion. Probably the former,
   but document the choice.
6. **String literals as values.** Currently the lexer's
   `THash` and `TIdent` carry `int list`. Tuplet's runtime
   string handling is via Forth's `WORD`/`COUNT`/etc. The
   prelude might want strings as a mintable abstract type
   (`*type String = ...` with a print verb).

## What the PoC commits to

The PoC ships **only the kernel + a sliver of layer 1**: the
`do..while` `*syntax` declaration plus enough scalar
arithmetic to write the demo loop. Everything else in this
document is "the language can grow into this," demonstrated
by the do..while example proving the mechanism is real.

After the PoC, the natural increments are:

- Layer 1 + Layer 2 (control flow + arithmetic) -- one prelude
  saga.
- Layer 3 (lists, options) -- second prelude saga.
- Layer 4 (errors) once Forth `CATCH`/`THROW` is verified.
- Layer 5 (modules) once the Tuplet parser supports
  filename-based namespacing (mirroring sw-cor24-ocaml).
- Layers 6-12 as user-driven needs arise.

Each layer is a new saga in the spirit of the existing arc.
