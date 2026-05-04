Completed parser-backed IR coverage for the remaining tuplet-ir saga acceptance points.

- Added `src/ir_parse_call_main.ml` and `tuplet_ir_parse_call` to cover shallow call-site tuple splicing: `coord2` is lowered as a tuple load before scalar pushes and `CALL ident:plot`.
- Added `src/ir_parse_unbound_main.ml` and `tuplet_ir_parse_unbound_fail` to verify fail-fast checker rejection before IR emission.
- Updated `docs/ir.md` with the call-splicing dump shape and fail-fast behavior.
- Kept source-backed IR lowering gated on `sw-cor24-ocaml#33`; no local limits were raised and no failing source-backed baseline was committed.

Validation:

- `REG_RS_DATA_DIR=work/reg-rs reg-rs run -p tuplet_ir_parse_call`
- `REG_RS_DATA_DIR=work/reg-rs reg-rs run -p tuplet_ir_parse_unbound_fail`
- `REG_RS_DATA_DIR=work/reg-rs reg-rs run -p tuplet_ir_parse_tuple_assign`
- `REG_RS_DATA_DIR=work/reg-rs reg-rs run -p tuplet_check_parse_call_pass`
- `REG_RS_DATA_DIR=work/reg-rs reg-rs run -p tuplet_check_parse_unbound_fail`
- `git diff --check`

The IR saga can close as parser-backed complete. The next work should start a Forth emitter/codegen saga, while treating source-backed IR demos as blocked until `sw-cor24-ocaml#33` is fixed.
