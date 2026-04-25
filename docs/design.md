# Tuplet -- Design

Low-level design for the Tuplet PoC: compiler pipeline, AST, stack
IR, and the builtin verb registry. Complements `docs/prd.md` (what
Tuplet is) and `docs/grammar.md` (the surface syntax).

## Pipeline

```
source.tup
   |
   v
+------+     +--------+     +-----+     +-----------------+
| lex  | --> | parse  | --> | AST | --> | name resolution |
+------+     +--------+     +-----+     +-----------------+
                                              |
                                              v
                                        +---------------+
                                        | arity checker |
                                        +---------------+
                                              |
                                              v
                                          +--------+
                                          | IR gen |
                                          +--------+
                                              |
                                              v
                            +-----+-----+-----+-----+
                            |                       |
                            v                       v
                    +---------------+       +----------------+
                    | interpreter   |       | Forth emitter  |
                    | (cross check) |       | (runtime path) |
                    +---------------+       +----------------+
                                                     |
                                                     v
                                             forth generated code
                                                     |
                                                     v
                                              cor24-run (emulator)
```

The interpreter backend exists mainly as a reference oracle for
tests: every program that compiles to Forth also runs in the
in-process interpreter, and reg-rs compares the two outputs to
catch emitter regressions.

## AST types

Primary form (idiomatic OCaml):

```ocaml
type name = string

type op =
  | OpAdd | OpSub | OpMul
  | OpMax  | OpMin  | OpDiv
  | OpMax2 | OpMin2 | OpDiv2

type expr =
  | EInt    of int
  | EBool   of bool
  | EPct    of int            (* 0..100 *)
  | ESymbol of string         (* Red, Green, Blue, ... *)
  | EName   of name
  | EBinary of expr * op * expr
  | ECall   of name * expr list
  | ETuple  of expr list      (* comma-separated RHS, e.g., 3, 9 *)

type pattern =
  | PName  of name            (* single lvalue: scalar or tuple-var *)
  | PTuple of name list       (* destructuring: a, b, c *)

type field = { f_name : name }

type sigdecl = {
  s_name    : name;
  s_inputs  : field list;
  s_outputs : field list;
}

type tupdecl = {
  t_name   : name;            (* e.g. "coord2" *)
  t_fields : field list;      (* length must match name's arity *)
}

type stmt =
  | SDecl      of tupdecl     (* coord2 -> (x y) *)
  | SSignature of sigdecl     (* plot(x y color c?) -> (success?) *)
  | SAssign    of pattern * expr
  | SExpr      of expr
  | SComment   of string

type program = stmt list
```

Name resolution produces a symbol table mapping each name to one of:
`SymScalar`, `SymTuple of arity`, `SymVerb of in_arity * out_arity`.

### OCaml-subset compatibility (sw-cor24-ocaml)

`sw-cor24-ocaml` today supports: ints, bools, strings, lists, pairs,
options, pattern matching, `let rec`, qualified names. It does **not
document** user-defined algebraic data types or records.

If user-defined variants turn out to be unavailable, fall back to a
tagged-tuple encoding:

```ocaml
(* expr as ("tag", payload) pairs; payload shape per tag. *)
let e_int n          = ("EInt",    (n, 0, ""))
let e_bool b         = ("EBool",   (0, (if b then 1 else 0), ""))
let e_pct p          = ("EPct",    (p, 0, ""))
let e_symbol s       = ("ESymbol", (0, 0, s))
let e_name s         = ("EName",   (0, 0, s))
(* EBinary / ECall / ETuple encoded as nested tagged tuples. *)
```

Pattern-match by the tag string in the first slot. This is verbose
but fits the subset we have.

**Upstream dependency.** If custom variants are needed for
readability at scale, file an issue at `sw-embed/sw-cor24-ocaml`
asking for user-defined sum types; do not switch away from OCaml
to avoid the limitation. Track under `docs/tooling-smoke.md` -> 
Blocked once filed.

## Stack IR

A linear list of instructions executed on an operand stack of value
cells (int-tagged for the PoC).

```ocaml
type instr =
  | IPushInt    of int
  | IPushBool   of bool
  | IPushPct    of int             (* 0..100 *)
  | IPushSymbol of string          (* e.g. "Red" *)
  | ILoad       of name            (* scalar load: ( -- x ) *)
  | IStore      of name            (* scalar store: ( x -- ) *)
  | ILoadTuple  of name * int      (* ( -- v1 v2 ... vN ) *)
  | IStoreTuple of name * int      (* ( v1 v2 ... vN -- ) *)
  | ICall       of name * int      (* N inputs consumed *)
  | IBinOp      of op
```

### Stack effects

| Instruction              | Effect                                 |
|--------------------------|----------------------------------------|
| `IPushInt n`             | `( -- n )`                             |
| `IPushBool b`            | `( -- b )`                             |
| `IPushPct p`             | `( -- p )`  -- percent as int 0..100   |
| `IPushSymbol s`          | `( -- sym )` -- resolved at emit time  |
| `ILoad x`                | `( -- v )`                             |
| `IStore x`               | `( v -- )`                             |
| `ILoadTuple (t, n)`      | `( -- v1 v2 ... vn )` -- topmost last  |
| `IStoreTuple (t, n)`     | `( v1 v2 ... vn -- )` -- topmost last  |
| `ICall (v, n)`           | `( a1 ... an -- r1 ... rk )`, k from   |
|                          | verb's declared output arity            |
| `IBinOp op`              | `( a b -- r1 ... rk )`, k from op arity |

**Tuple order convention.** Fields are pushed in declaration order:
for `coord2 -> (x y)`, after `ILoadTuple ("coord2", 2)` the stack
top is `y` and `x` is directly below. `IStoreTuple` consumes them in
the same reading order (so the source `coord2 <- 3, 9` pushes 3
then 9, then stores).

## Builtin verb registry

Shipped with the PoC. All arities are static.

| Name    | In | Out | Notes                                    |
|---------|----|-----|------------------------------------------|
| `+`     | 2  | 1   | Integer add.                             |
| `-`     | 2  | 1   | Integer sub.                             |
| `*`     | 2  | 1   | Integer mul.                             |
| `max`   | 2  | 1   | `max(a, b)`                              |
| `min`   | 2  | 1   | `min(a, b)`                              |
| `div`   | 2  | 1   | Integer division, truncates.             |
| `max2`  | 2  | 2   | Returns `(hi, lo)` -- first is >=.       |
| `min2`  | 2  | 2   | Returns `(lo, hi)` -- first is <=.       |
| `div2`  | 2  | 2   | Returns `(quotient, remainder)`.         |
| `plot`  | 4  | 1   | `(x y color c?) -> (success?)`; the PoC  |
|         |    |     | backend prints the args and returns 1.   |

Colors (`Red`, `Green`, `Blue`) are ESymbol literals resolved to
small integers at emit time (e.g. `Red = 82` -- ASCII 'R').
A stable symbol->int table lives alongside the Forth emitter.

## Worked example

Source:

```
coord2 -> (x y)
coord2 <- 3, 9
success? <- plot(coord2 Red 50%)
```

### AST (pseudo-OCaml)

```ocaml
[
  SDecl { t_name = "coord2"; t_fields = [{f_name="x"}; {f_name="y"}] };
  SAssign (PName "coord2",
           ETuple [EInt 3; EInt 9]);
  SAssign (PName "success?",
           ECall ("plot",
                  [EName "coord2";
                   ESymbol "Red";
                   EPct 50]));
]
```

### Stack IR

```
; SDecl coord2 -> (x y)            -- no IR emitted; just updates
;                                     the symbol table (SymTuple 2).

; coord2 <- 3, 9
IPushInt 3
IPushInt 9
IStoreTuple ("coord2", 2)

; success? <- plot(coord2 Red 50%)
ILoadTuple  ("coord2", 2)          ; pushes 3 then 9
IPushSymbol "Red"                  ; resolves to int at emit
IPushPct    50
ICall       ("plot", 4)            ; consumes 4, produces 1
IStore      "success?"
```

Arity check for the call: `coord2` (2) + `Red` (1) + `50%` (1) = 4,
which matches `plot`'s declared in-arity. OK.

### Expected Forth (detailed rules in `docs/lowering.md`)

```
\ Per-tuple: backing variables and ! / @ words.
VARIABLE coord2-x
VARIABLE coord2-y
: coord2!  ( x y -- )    coord2-y ! coord2-x ! ;
: coord2@  ( -- x y )    coord2-x @ coord2-y @ ;

VARIABLE success?q      \ scalar backing
: success?!  ( v -- )   success?q ! ;
: success?@  ( -- v )   success?q @ ;

\ Program body.
3 9 coord2!
coord2@ 82 50 plot success?!
```

(`82` is the symbol table entry for `Red`; `50` is the percent
literal as int; `plot` is a builtin word provided by the Tuplet
runtime layer that sits on top of `sw-cor24-forth`.)

## Open questions

- **Passing a tuple as one value.** No syntax yet; see `docs/grammar.md`
  splicing TODO. Design deferred.
- **Negative percent / percent arithmetic.** Current PoC treats `%`
  only as a literal constructor; there is no `(50% + 25%)` form.
- **String / text output.** `plot`'s mock output assumes the runtime
  has a way to print, which for the PoC is `.` or `EMIT` in Forth.
  `sw-cor24-forth` has both. Nothing upstream needed.
- **Boolean return of `plot`.** Forth has no native bool type;
  represent as `0 = false`, `-1 = true`, matching Forth convention.

## Upstream dependencies

None filed yet. If user-defined sum types or records turn out to be
required by the parser implementation, file at
`sw-embed/sw-cor24-ocaml` and record here.
