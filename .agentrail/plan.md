# Saga: tuplet-forth-emit

## Goal

Emit deterministic Forth from the parser-backed IR subset that Tuplet can already lower, then grow it into a runnable cor24 Forth demo path without depending on the source-backed OCaml memory runner blocked by `sw-cor24-ocaml#33`.

## Source of truth

- `docs/lowering.md` defines the intended IR-to-Forth mapping.
- `docs/ir.md` defines the currently implemented IR dump subset.
- `docs/design.md` provides stack order and tuple splicing semantics.
- `docs/poc-goals.md` defines the later REPL milestone, but this saga starts with generated Forth files and deterministic baselines.

## In scope

- Forth emitter scaffold for the checker-complete parser-backed IR subset.
- Deterministic Forth dumps for tuple declarations, scalar stores, tuple loads, scalar literals, percent literals, and shallow calls.
- Focused reg-rs baselines for the existing coord2 assignment and plot call-splicing IR fixtures.
- A later step to run generated Forth under `sw-cor24-forth`/`cor24-run` if kernel/runtime wiring permits.

## Out of scope

- Source-backed IR/Forth demos while `sw-cor24-ocaml#33` remains open.
- Full prelude, macro expansion, `prim/forth`, thunks, and do/while REPL.
- Editing sibling repos or locally raising runtime limits.

## End state

- Parser-backed checked programs can lower to IR and then to stable Forth text.
- The generated Forth for the current call-splicing demo is either runnable under `cor24-run` with a reg-rs baseline or blocked by a clearly diagnosed upstream issue.
- Docs identify exactly what can be demoed and what remains gated.
