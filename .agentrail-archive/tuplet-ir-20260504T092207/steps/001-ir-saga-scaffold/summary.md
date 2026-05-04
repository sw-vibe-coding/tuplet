Added the initial Tuplet IR scaffold for the checker-complete coord2 tuple assignment path.

- Added `src/ir.ml` with checker-gated lowering for tuple signatures, tuple loads, scalar pushes, shallow calls, and tuple-pattern stores.
- Added deterministic parser-backed IR dump driver and reg-rs baseline for `coord2` declaration plus `a, b <- coord2`.
- Added a memory-backed IR runner for the OCaml issue #33 repro, but did not commit a failing source-backed reg-rs baseline.
- Documented current IR scope, stack store order, deferrals, and the source-backed runtime gate in `docs/ir.md`.

Validation:

- `REG_RS_DATA_DIR=work/reg-rs reg-rs run -p tuplet_ir_parse_tuple_assign`
- `REG_RS_DATA_DIR=work/reg-rs reg-rs run -p tuplet_check_parse_tuple_assign_pass`
- `REG_RS_DATA_DIR=work/reg-rs reg-rs run -p tuplet_check_source_tuple_assign_pass`
- `git diff --check`

Blocked/gated:

- Source-backed IR lowering currently stops after `Lex_bridge.parse_next ()` when the IR module is loaded. Opened `sw-cor24-ocaml#33` with a concrete repro. Tuplet should validate `scripts/run-lex-ir-fixture.sh tests/checker/source_tuple_assign.input` after that OCaml runtime issue is fixed.
