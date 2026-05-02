# Tuplet -> Forth Lowering

The rule-by-rule mapping from Tuplet stack IR (see `docs/design.md`)
to Forth source executable by `sw-cor24-forth` under `cor24-run`.
This is the spec the Forth emitter follows.

## Runtime words the PoC assumes

Only words actually emitted by the compiler or used in builtin verb
bodies. All are provided by the `sw-cor24-forth` kernel (`forth.s`,
entry points confirmed by inspection).

| Word    | Emitted by           | Kernel entry point   |
|---------|----------------------|----------------------|
| `:`     | every `:` definition | `entry_colon`        |
| `;`     | every `:` definition | `entry_semi`         |
| `CREATE`| tuple / scalar decl  | `entry_create`       |
| `,`     | tuple / scalar decl  | `entry_comma`        |
| `ALLOT` | reserved for future  | `entry_allot`        |
| `!`     | scalar / tuple store | `entry_store`        |
| `@`     | scalar / tuple load  | `entry_fetch`        |
| `+`     | `IBinOp OpAdd`       | `entry_plus`         |
| `-`     | `IBinOp OpSub`       | `entry_minus`        |
| `*`     | `IBinOp OpMul`       | `entry_star`         |
| `/MOD`  | `div`, `div2` bodies | `entry_slashmod`     |
| `<`     | `max`, `min` bodies  | `entry_less`         |
| `DUP`   | `max`, `min` bodies  | `entry_dup`          |
| `DROP`  | `div` body           | `entry_drop`         |
| `SWAP`  | `max`, `min` bodies  | `entry_swap`         |
| `OVER`  | `max2`, `min2` bodies| `entry_over`         |
| `IF`    | `max`, `min` bodies  | `entry_if`           |
| `ELSE`  | `max`, `min` bodies  | `entry_else`         |
| `THEN`  | `max`, `min` bodies  | `entry_then`         |
| `EMIT`  | `plot` body          | `entry_emit`         |
| `.`     | `plot` body          | `entry_dot`          |
| `CR`    | `plot` body          | `entry_cr`           |
| `SPACE` | `plot` body          | `entry_space`        |

Notably **not** assumed:

- `VARIABLE` -- the kernel has no such word. We use
  `CREATE <name> 0 ,` (create a named address and comma-store an
  initial zero cell), which is what VARIABLE is sugar for anyway.
- `/` and `MOD` -- absent as separate words, but `/MOD` is present
  and more fundamental. We use `/MOD` directly; single-output
  division is `/MOD SWAP DROP`.
- `0<` -- absent; we do `0 <` when needed.

These three are tracked as optional polish for upstream, not
blockers. See `Upstream dependencies` at the bottom.

## Lowering per IR instruction

| IR                         | Emitted Forth                       |
|----------------------------|-------------------------------------|
| `IPushInt n`               | `n` (decimal literal)               |
| `IPushBool true`           | `-1`                                |
| `IPushBool false`          | `0`                                 |
| `IPushPct p`               | `p` (integer 0..100)                |
| `IPushSymbol s`            | `N` where N = symbol table `(s)`    |
| `ILoad x`                  | `x@`                                |
| `IStore x`                 | `x!`                                |
| `ILoadTuple (t, n)`        | `t@` (the generated `n`-output word)|
| `IStoreTuple (t, n)`       | `t!` (the generated `n`-input word) |
| `ICall (v, n)`             | `v` (the verb word; args already on)|
| `IBinOp OpAdd`             | `+`                                 |
| `IBinOp OpSub`             | `-`                                 |
| `IBinOp OpMul`             | `*`                                 |
| `IBinOp OpMax`             | `max`                               |
| `IBinOp OpMin`             | `min`                               |
| `IBinOp OpDiv`             | `div`                               |
| `IBinOp OpMax2`            | `max2`                              |
| `IBinOp OpMin2`            | `min2`                              |
| `IBinOp OpDiv2`            | `/MOD`                              |

Note: `OpDiv2` goes straight to `/MOD` -- the kernel word already
has the `(n d -- q r)` stack effect that `div2` needs.

## Lowering per surface construct

### Tuple declaration: `▪nameₙ ───‣ ⎛f1 f2 ... fN⎠`

```
CREATE <name>-f1 0 ,
CREATE <name>-f2 0 ,
...
CREATE <name>-fN 0 ,
: <name>!  ( v1 v2 ... vN -- )   <name>-fN !  ...  <name>-f2 !  <name>-f1 ! ;
: <name>@  ( -- v1 v2 ... vN )   <name>-f1 @  <name>-f2 @  ...  <name>-fN @ ;
```

`<name>!` stores in **reverse** field order because stack top is the
last-pushed value (=last field). `<name>@` fetches in **forward**
field order so the first field ends up deepest and the last field
is on top, matching the stack-top-last convention in
`docs/design.md`.

### Scalar declaration (implicit, on first assignment)

When the emitter sees a scalar name `x` assigned for the first
time, it emits once at the top of the output:

```
CREATE x-cell 0 ,
: x!  ( v -- )   x-cell ! ;
: x@  ( -- v )   x-cell @ ;
```

The `-cell` suffix on the backing address disambiguates from the
accessor words.

### Signature declaration: `▪name⎛inputs⎠ ───‣ ⎛outputs⎠`

Emits nothing. Signatures are compile-time metadata for the arity
checker. The verb's runtime body is either a builtin (shipped in
the prelude, see below) or runtime-linked.

### Scalar assignment: `x ⟵ expr`

```
<forth for expr>   \ leaves one value on the stack
x!
```

### Destructuring assignment: `a , b , ... , k ⟵ expr`

```
<forth for expr>   \ leaves N values on the stack (top = last name)
k!  ...  b!  a!    \ reverse order: top pops into the last name
```

### Tuple-var assignment: `coord₂ ⟵ expr`

Same form as destructuring, using the generated `coord2!` word:

```
<forth for expr>   \ leaves N values (N = coord2's arity)
coord2!
```

### Call: `f⎛args⎠` (splicing is the default)

```
<forth for arg1>
<forth for arg2>
...
<forth for argK>
f                  \ consumes sum(arities), pushes f's output arity
```

A tuple variable argument contributes its arity automatically because
its Forth form is `coord2@` which pushes N values.

### Binary expression: `a OP b`

```
<forth for a>
<forth for b>
<op-word>          \ from the "Lowering per IR instruction" table
```

No precedence in the PoC; parens in the source force grouping.

## Builtin verb bodies (Tuplet prelude)

The Forth emitter prepends this prelude to every generated program.
All are colon definitions composed from kernel primitives.

```
\ === Tuplet prelude ===

\ Max / min scalar.
: max  ( a b -- m )   OVER OVER < IF SWAP THEN DROP ;
: min  ( a b -- m )   OVER OVER < IF DROP ELSE SWAP DROP THEN ;

\ Max / min pair: (hi lo) and (lo hi).
: max2 ( a b -- hi lo )   OVER OVER < IF SWAP THEN ;
: min2 ( a b -- lo hi )   OVER OVER < 0= IF SWAP THEN ;

\ Single-output integer division; div2 is simply /MOD.
: div  ( a b -- q )   /MOD SWAP DROP ;

\ plot ( x y color c% -- success? )
\ Minimal builtin: print the four args separated by spaces and a
\ newline, return -1 (Forth true).
: plot ( x y color c% -- success? )
  >R >R >R >R
  R> .  R> .  R> .  R> .
  CR
  -1
;
```

Note: `max`, `min`, `max2`, `min2` use `OVER OVER` rather than a
`2DUP` because the kernel's word list does not include `2DUP`. This
is a straight composition, not a workaround.

### `plot` stack effect, step-by-step

The four `>R` calls move the top-of-stack into the return stack in
reverse (so `x` ends up deepest on the R-stack and `c%` on top,
then the `R>` pops reverse that and leave them in declaration
order). The trailing `CR` prints a newline; `-1` pushes the truthy
return value consumed by the caller's `IStore`.

## Worked example

Source (same as `docs/design.md`):

```
▪coord₂ ───‣ ⎛x y⎠
coord₂ ⟵ 3 , 9
successˀ ⟵ plot⎛coord₂ Red 50%⎠
```

IR:

```
IStoreTuple ("coord2", 2)
ILoadTuple  ("coord2", 2)
IPushSymbol "Red"
IPushPct    50
ICall       ("plot", 4)
IStore      "success?"
```

Lowered Forth (prelude omitted for brevity; symbol table resolves
`Red` to `82`; glyph names are normalized before emission):

```forth
\ --- declaration: ▪coord₂ ───‣ ⎛x y⎠ ---
CREATE coord2-x 0 ,
CREATE coord2-y 0 ,
: coord2!  ( x y -- )   coord2-y ! coord2-x ! ;
: coord2@  ( -- x y )   coord2-x @ coord2-y @ ;

\ --- implicit scalar decl for success? ---
CREATE success?-cell 0 ,
: success?!  ( v -- )   success?-cell ! ;
: success?@  ( -- v )   success?-cell @ ;

\ --- body ---
3 9 coord2!            \ IPushInt 3, IPushInt 9, IStoreTuple coord2 2
coord2@                \ ILoadTuple coord2 2       (pushes 3, 9)
82                     \ IPushSymbol "Red"         (symbol -> 82)
50                     \ IPushPct 50
plot                   \ ICall plot 4              (consumes 4, pushes 1)
success?!              \ IStore success?
```

After this runs under `cor24-run`, the expected UART output is
`3 9 82 50 ` followed by a newline -- the `plot` body's echo.

## File layout convention

The Tuplet CLI emits one `.fs` file per compiled program:

```
work/generated/<basename>.fs
```

`work/generated/` is created on demand and gitignored. The file is
a self-contained Forth source: prelude + generated program body.

The test harness (a later step, likely `tuplet-run.sh`) will
concatenate the kernel `forth.s` and the generated `.fs` and feed
the composite to `cor24-run`, exactly mirroring the smoke test in
`docs/tooling-smoke.md`. The harness captures the UART output and
hands it to reg-rs for baseline comparison.

## Upstream dependencies

No blockers. The following are optional enhancements that would
slightly simplify the Tuplet emitter if added to
`sw-cor24-forth`; none affect correctness:

- `VARIABLE <name>` as kernel sugar for `CREATE <name> 0 ,`.
- `/` as kernel sugar for `/MOD SWAP DROP`.
- `MOD` as kernel sugar for `/MOD DROP`.
- `2DUP` as kernel sugar for `OVER OVER`.

If these are filed as enhancement issues upstream, record the
issue numbers here. Not filed at this time.
