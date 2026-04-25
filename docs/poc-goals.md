# Tuplet PoC Goals

The single demonstrable artifact this project is aiming at.

## North Star

A **demoable REPL** running a stripped-down Tuplet that lets a
user, in a single session, **define a new control-flow construct
in Tuplet itself** and then use it. The new construct must fit
the language's left-and-right-arrow paradigm (`<-` assignment,
`->` mapping arrow) and must be added via the `syntax`
declaration form -- no compiler change required.

Concretely:

```
$ tuplet repl
> n <- 0
> syntax do _ while _ end expand
.   prim/forth "BEGIN"  _1  _2  prim/forth "UNTIL"
> do
.   n <- n + 1
.   n prim/forth "."
.   prim/forth "SPACE"
. while  n < 3  end
1 2 3
> n
3
> #
```

The transcript above is the **acceptance scenario**. If the REPL
can produce that output, with the user typing all of it
(including the `syntax` declaration), the PoC is met.

## Why `do..while` and not `if..then..else`

`do..while` is a strictly smaller demo target than
`if..then..else`:

| Construct                | Slots | Branches at runtime | Forth lowering        |
|--------------------------|-------|---------------------|-----------------------|
| `if _ then _ else _ end` | 3     | 2 (then or else)    | `IF`, `ELSE`, `THEN`  |
| `do _ while _ end`       | 2     | 1 (top of loop)     | `BEGIN`, `UNTIL`      |

Two slots vs three, one branch target vs two. Same machinery in
both cases (`syntax T expand E` + `prim/forth` escape), and
nothing in the kernel needs to know the construct exists. The
PoC ships only the smaller of the two.

`if..then..else` and `while..do..end` arrive in the prelude
saga (see `docs/plan.md` saga 7) once the architecture is
proven on the smaller case.

## Stripped-down Tuplet for the PoC REPL

Only the subset needed for the acceptance scenario above. Every
form below has spec text in the existing scaffold docs.

| Form                            | Why it's needed                       |
|---------------------------------|---------------------------------------|
| Integer literals                | The `0`, `1`, `3` in the scenario.    |
| Identifier (ASCII letters + digits) | Variable name `n`.                |
| Scalar assignment `name <- expr`| State updates (`n <- n + 1`).         |
| Binary `+` and `<`              | Arithmetic and the loop test.         |
| Bare expression statement       | The `n` line at the end (print scalar).|
| `prim/forth "WORD"` raw escape  | Used inside the `syntax` expansion.   |
| `syntax T expand E` declaration | The whole point of the demo.          |
| Line comment `#`                | Quality-of-life only.                 |

Everything else from `docs/grammar.md` is **out of scope for the
PoC milestone**, including:

- Tuple variable declarations (`coord2 -> (x y)`).
- Multi-output verbs (`max2`, `min2`, `div2`).
- Call-with-splice (`plot(coord2 Red 50%)`).
- Anonymous verb literals `{...}`.
- Percent literals (`50%`).
- Most Unicode aliases (ASCII surface only for the PoC; Unicode
  arrives later as a pure lexer extension).
- The full builtin verb registry.
- LED / board I/O.

These are real language features and will arrive in their own
sagas, but none of them are gated by the PoC milestone.

## When the PoC milestone is met (in plan terms)

The PoC is a **vertical slice** through the existing eight-saga
arc, not a separate saga. It is met when:

- `tuplet-lexer` recognizes the stripped-down token set above,
  including dynamic literal registration.
- `tuplet-parser` can parse a `syntax` declaration, register the
  template, and parse subsequent input that matches it.
- `tuplet-checker` arity-checks the registered template (each
  slot has output arity 1; whole template has output arity 0).
- `tuplet-ir` lowers `do..while` use sites via the registered
  expansion.
- `tuplet-forth-emit` round-trips the IR through `cor24-run` and
  produces the expected UART output.
- A REPL driver (a small addition during or after
  `tuplet-forth-emit`) reads stdin one logical statement at a
  time, compiles, runs, and prints output.

We do **not** need:

- The full prelude (`tuplet-prelude` saga). For the PoC, the
  user types the `syntax` declaration directly, demonstrating
  the mechanism. A pre-loaded prelude is a polish step.
- Anonymous verb literals. The `expand` form does textual
  substitution -- no thunks, no xts, no `:NONAME`.
- The demo gallery (`tuplet-demos` saga). One scenario in a
  README is enough for the PoC.

This means the PoC milestone lands at the **end of saga 6
(`tuplet-forth-emit`)** plus a small REPL driver, **not** at
the end of saga 8.

## REPL behavior

For the PoC, the REPL keeps it simple. Each user input is one
logical statement (terminated by newline at outer indent).
Multi-line constructs use a continuation prompt (`. `) until the
opening token sees its matching close.

State persistence between inputs: scalar variable values and the
syntax registry survive across inputs. The simplest
implementation:

1. Maintain a Tuplet-side environment (variable->value map, the
   syntax registry) inside the OCaml-subset REPL process.
2. Each input compiles to a fresh Forth program: the kernel
   prelude + reconstructed scalar `CREATE`s + the new statement.
3. Run that program through `cor24-run` and capture the output
   delta from the previous run.

This is wasteful per input but correct, requires nothing from
the runtime beyond what the existing smoke tests already use,
and is good enough for the PoC. Optimizing to a persistent
`cor24-run` is a follow-up.

## Acceptance criteria

The PoC is met when **all** of the following hold:

1. `tuplet repl` (or equivalent invocation) starts a REPL.
2. The exact transcript above can be reproduced by typing it.
   Output bytes match `1 2 3\n3\n` (whitespace exact).
3. A reg-rs baseline exercises a scripted REPL session that
   defines `do..while` and uses it. The baseline is committed
   to `work/reg-rs/tuplet_poc_dowhile.{rgt,out}`.
4. A short `docs/poc-demo.md` walks through the scenario with
   commentary on what's happening at each step.
5. The user can substitute `do..while` for some other
   two-slot template (e.g. `unless _ do _ end`) and the REPL
   accepts it -- proving the mechanism is general, not
   special-cased.

Item 5 is the part that proves "the language can add language
features." If only `do..while` works and `unless` mysteriously
fails, the PoC is a sham.

## Out of PoC scope (deferred to later sagas)

- `if..then..else` (saga 7 prelude).
- `while..do..end` (saga 7 prelude).
- `match..with` (saga 7 prelude).
- Tuple variables and destructuring (saga 4-7).
- Multi-output verbs (saga 4-7).
- LED / board I/O demos (saga 8).
- Unicode glyph lexing (separate later saga).
- Hygiene / name capture (deliberately not in PoC).
- Mixfix precedence levels (PoC uses longest-match; document
  the corner cases).
