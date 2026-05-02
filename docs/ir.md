# Tuplet IR

The IR saga starts with the checker-complete subset only. It lowers the
current parser scaffolding AST after running `Checker.check`, then dumps
a deterministic stack-oriented listing. This is not a Forth emitter and
does not execute code.

## Current Scope

Supported source shapes:

- tuple signatures, dumped as `DECLARE ... inputs:N outputs:M`;
- tuple-pattern assignment;
- scalar integer literals `0` through `9` and percent literal `50%`;
- name loads, tuple loads, and shallow calls when their signatures are
  known to the checker.

The initial IR dump intentionally includes declaration metadata because
the future Forth emitter needs tuple backing storage as well as linear
stack instructions.

## Example

Tuple declaration plus destructuring assignment:

```text
IR
DECLARE ident:coord2 inputs:0 outputs:2
LOAD_TUPLE ident:coord2 arity:2
STORE ident:b
STORE ident:a
ENDIR
```

The store order is reversed for tuple destructuring because the last
field is on top of the stack.

Shallow calls splice tuple-valued arguments by emitting the tuple load
before scalar pushes and the final call:

```text
IR
DECLARE ident:plot inputs:4 outputs:1
DECLARE ident:coord2 inputs:0 outputs:2
LOAD_TUPLE ident:coord2 arity:2
PUSH_INT 7
PUSH_PCT 50
CALL ident:plot inputs:4 outputs:1
ENDIR
```

Checker rejection is fail-fast. `Ir.lower` runs `Checker.check` before
emitting IR and returns the checker error unchanged.

## Deferrals

- No Forth emission.
- No interpreter.
- No nested expression tree lowering beyond the current parser groups.
- No `prim/forth`, colon forms, or anonymous-verb thunks until those
  are represented by parser and checker.

## Runtime Gate

The parser-backed IR fixture is the acceptance path for this scaffold.
The equivalent memory-backed source runner is currently gated by
`sw-cor24-ocaml#33`: with the IR module loaded, the OCaml runtime stops
after `Lex_bridge.parse_next ()` on the same 32-byte input that the
checker-only memory runner accepts. Do not raise local Tuplet limits to
hide this; validate the source-backed IR fixture after the OCaml-side
runtime issue is fixed.
