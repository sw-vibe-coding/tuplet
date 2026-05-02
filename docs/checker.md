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
Tuple variable signatures such as `▪coord₂ ───‣ ⎛x y⎠` are represented
with input arity `0` and output arity `2`.

The checker now has two layers of coverage:

- hand-built AST baselines for unit-level checker behavior; and
- parser-backed baselines that run `src/parser.ml` first, then pass
  the resulting AST to `src/checker.ml`.

Parser-backed coverage currently includes tuple assignment pass,
unbound RHS name failure, tuple-pattern arity mismatch failure, and
call arity pass with tuple splicing.

Real-source checker handoff is currently blocked upstream. The first
`sw-embed/sw-cor24-ocaml#30` fix made the allocation-after-parse repro
pass, but the full source checker path still traps when the checker is
run over a memory-backed parsed program. The current in-tree repro is
`scripts/repro-ocaml-issue30-source-check-trap.sh`; upstream tracking
remains `sw-embed/sw-cor24-ocaml#30`.

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
- scalar assignment through parser-backed tests; the parser currently
  gives the checker reliable tuple-pattern assignment groups only when
  the LHS has comma shape;
- syntax-match slot arity propagation;
- `prim/forth` or colon forms;
- final typed-AST node encoding;
- lowering, interpretation, or Forth emission.

Those belong to later checker steps or downstream sagas. The parser
deferrals are recorded in `docs/parser-saga-exit-audit.md`.
