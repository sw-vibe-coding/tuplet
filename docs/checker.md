# Tuplet Checker

The checker consumes the parser saga's current scaffolding AST and
adds deterministic name and arity validation. This first slice is
intentionally small: it supports the parser-complete tuple and call
shapes needed to start demo parity work without pulling in IR,
interpretation, or Forth emission.

## Current Scope

Supported statement shapes:

- `STMT signature` with `name`, `inputs`, and `outputs` groups.
- `STMT assign` with `pattern` and `expr` groups.
- `STMT call` with `callee` and `args` groups.

The checker builds a signature environment as it walks the program.
Each signature binds one name to an input arity and an output arity.
Tuple variable signatures such as `*coord2 -> (x y)` are represented
with input arity `0` and output arity `2`.

## Rules

- Assignment arity: the number of names in the `pattern` group must
  equal the summed output arity of the `expr` group.
- Name resolution: names referenced by assignment expressions or call
  callees must already be bound by a signature.
- Call arity: the summed arity of the `args` group must equal the
  callee's input arity. The call expression's output arity is the
  callee's declared output arity.
- Scalar integer and percent literals used by the first fixtures count
  as arity `1`.

## Diagnostics

Checker output is deterministic.

Passing programs dump:

```text
CHECK OK
BIND ident:coord2 inputs:0 outputs:2
ASSIGN arity:2
ENDCHECK
```

Failing programs dump one `ERROR` line:

```text
ERROR  checker:unbound-name:ident:missing2
ERROR  checker:arity-mismatch expected:1 actual:2
```

## Current Deferrals

This checker slice does not yet handle:

- nested expression trees;
- syntax-match slot arity propagation;
- `prim/forth` or colon forms;
- final typed-AST node encoding;
- lowering, interpretation, or Forth emission.

Those belong to later checker steps or downstream sagas. The parser
deferrals are recorded in `docs/parser-saga-exit-audit.md`.
