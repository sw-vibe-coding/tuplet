Started the `tuplet-forth-emit` saga and archived the completed `tuplet-ir` saga.

- Added `src/forth_emit.ml`, a deterministic text emitter for the current parser-backed IR subset: tuple declaration, scalar store declarations, tuple load, integer and percent pushes, scalar store, and shallow calls.
- Added parser-backed drivers for tuple assignment and plot call-splicing Forth emission.
- Added reg-rs baselines for both generated Forth dumps.
- Updated `docs/plan.md` to mark `tuplet-ir` done, interpreter deferred, and Forth emission in progress.
- Updated `docs/lowering.md` to document the current scaffold limitation: the IR carries tuple arity but not field names, so the emitter uses numbered tuple cells for now.

Validation:

- `REG_RS_DATA_DIR=work/reg-rs reg-rs run -p tuplet_forth_emit_parse_tuple_assign`
- `REG_RS_DATA_DIR=work/reg-rs reg-rs run -p tuplet_forth_emit_parse_call`
- `REG_RS_DATA_DIR=work/reg-rs reg-rs run -p tuplet_ir_parse_call`
- `REG_RS_DATA_DIR=work/reg-rs reg-rs run -p tuplet_ir_parse_tuple_assign`
- `git diff --check`

Source-backed IR/Forth remains gated on `sw-cor24-ocaml#33`; no local limits were raised and no sibling repos were edited.
