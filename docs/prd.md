# Tuplet -- Product Requirements Document

## Overview

Tuplet is an experimental infix programming language in which
expressions can emit multiple named values that flow directly into
other expressions. It combines infix readability with stack-based
execution semantics: tuple variables are first-class producers of
fixed-arity value streams, verbs are multi-output, and call-site
argument lists concatenate those streams without requiring the caller
to overload or repackage. The PoC compiles to Forth and runs on the
COR24 Forth runtime.

## Goals

- First-class named tuple bundles with a declared arity
  (e.g. `coord2` produces 2 values, `point4` produces 4).
- Multi-output verbs (e.g. `max2`, `min2`, `div2`) with explicit
  arity in their name.
- Multi-value destructuring assignment: `a, b <- coord2`.
- Call-site splicing: `plot(coord2 Red 50%)` expands to four
  arguments without plot being overloaded.
- Static arity checking at compile time -- every expression has a
  known output arity, every call has a known input arity.
- Lowering to Forth, exploiting its native multi-output stack words.
- ASCII surface syntax as the primary form, with Unicode aliases
  accepted for authoring comfort.

## Non-goals (initial PoC)

- Hindley-Milner type inference. Types are nominal/positional only.
- Modules, functors, namespaces.
- Exceptions or effect tracking.
- Garbage-collected heap. Values are stack cells.
- Floating point beyond percent literals (`50%` = 0.5 internally,
  represented as the runtime sees fit).
- Polymorphism, typeclasses, implicits.
- Separate compilation; the PoC is whole-program.

## Core concepts

**Tuple variable.** A name suffixed with an integer arity. Using the
name in expression position produces that many values on the stack.

```
coord2 <- 3, 9
```

**Verb signature.** Written with the mapping operator (Unicode
`---*` / ASCII `->`). Input and output value lists are parenthesized.

```
plot (x y color transparency) -> (success)
coord2 () -> (x y)
```

**Multi-value assignment.** LHS may be a comma-separated list of
names matching the RHS arity.

```
a, b <- coord2
q, r <- a max2 b
integer, fractional <- a div2 b
```

**Call-site splicing.** In a call, each argument contributes its
own arity to the callee's input list. Splicing is the default; a
tuple variable is spread, not boxed.

```
success <- plot(coord2 Red 50%)
```

Here `coord2` spreads to two values; `Red` and `50%` are one each;
`plot` consumes four inputs total and produces one.

## Surface syntax

Tuplet has two syntactic surfaces:

- **ASCII (primary).** Easy to type, parse, and diff. File
  extension `.tup`.
- **Unicode (aliases).** Matches the notation in
  `docs/research.txt` -- `<-` is `<-` (Unicode `left-arrow`), `->`
  is the heavy mapping arrow, `(` `)` are shell-bracket glyphs,
  `max2` has a subscript-2 glyph form, etc.

The full grammar lives in `docs/grammar.md` (next step).

## Example programs

```
# Tuple init and destructuring
coord2 <- 3, 9
a, b <- coord2

# Multi-output verb returning max then min
q, r <- 3 max2 5

# Integer and fractional parts of division
integer, fractional <- 7 div2 3

# Call-site splice with a 2-arity bundle
success <- plot(coord2 Red 50%)

# Signature-first style: declare then use
plot (x y color transparency) -> (success)
coord2 <- 3, 9
success <- plot(coord2 Red 50%)
```

## Implementation targets

- **Parser host:** the integer-subset OCaml interpreter at
  `sw-embed/sw-cor24-ocaml`. The Tuplet parser is written in the
  OCaml subset that interpreter supports (ints, bools, strings,
  lists, pairs, options, pattern matching, `let rec`, `read_line`,
  `print_endline`).
- **Runtime target:** the DTC Forth at `sw-embed/sw-cor24-forth`,
  running under the COR24 emulator (`cor24-run`).
- **Test harness:** `reg-rs` golden-output regression tests, covering
  both parser behaviour (AST dumps, arity errors) and end-to-end
  Forth execution of generated code.
- **Pipeline:** source `.tup` -> tokens -> AST -> arity-checked AST
  -> stack IR -> Forth source -> `cor24-run` UART output.

## Success criteria

The PoC is successful when:

1. The canonical sample programs parse without error.
2. Arity mismatches (wrong LHS count, wrong call arity) are
   detected and reported with a location.
3. A stack IR is emitted from valid ASTs.
4. A small interpreter evaluates the IR and produces expected output
   for arithmetic, destructuring, and multi-output verbs.
5. Generated Forth runs under `cor24-run` and produces the same
   result as the interpreter.
6. `reg-rs` captures golden baselines for 6 or more example
   programs, all passing.

## Risks

- **Unicode parsing.** The integer-subset OCaml host has limited
  string/char facilities; mixing UTF-8 glyphs with ASCII requires
  careful lexer design. Mitigation: author tests and core examples
  in ASCII; treat Unicode as an optional alias pass.
- **Splicing ambiguity.** Default splicing means a tuple variable
  always spreads. Passing a tuple as a single value (e.g. a future
  higher-order form) has no syntax yet; this is a deferred design
  question, flagged in the grammar doc.
- **Parser-host limits.** `sw-cor24-ocaml` is an integer-subset
  interpreter. Missing features (e.g., efficient dictionaries,
  large-string handling) will be filed as upstream issues against
  `sw-embed/sw-cor24-ocaml`, not worked around here.
- **Runtime-host limits.** COR24 ISA and Forth word set constraints
  may force IR changes. Missing words or bugs will be filed as
  upstream issues against `sw-embed/sw-cor24-forth`.
- **Scope creep.** The PoC deliberately omits typing, modules, and
  exceptions. Pressure to add any of these should be deflected to a
  future saga, not mixed into the Phase 0-8 arc.
