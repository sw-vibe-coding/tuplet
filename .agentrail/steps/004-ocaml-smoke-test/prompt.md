# Step: ocaml-smoke-test

Prove that the `sw-cor24-ocaml` toolchain at
`~/github/sw-embed/sw-cor24-ocaml` can run an OCaml program end-to-
end on this machine, and capture a `reg-rs` baseline inside THIS
repo so future sessions can detect regressions.

## Scope

Goal is wiring confidence, not Tuplet functionality. The program
under test is a trivial OCaml one-liner like `print_int 42`.

## Do

1. Inspect `~/github/sw-embed/sw-cor24-ocaml/README.md` and
   `justfile` to confirm the invocation pattern for running an
   `.ml` file. Expected:
   `~/github/sw-embed/sw-cor24-ocaml/scripts/run-ocaml.sh <file>`
   or `just -d <that-dir> run <file>` if present.
2. Create a trivial sample inside THIS repo (not upstream):
   `tests/smoke/ocaml_hello.ml` with body
   `let x = 41 + 1 in print_int x`.
3. Run it once manually to confirm it prints `42`.
4. Register a `reg-rs` test named e.g. `tuplet_ocaml_smoke`:
   ```
   reg-rs create -t tuplet_ocaml_smoke --timeout 60 \
     -c 'bash ~/github/sw-embed/sw-cor24-ocaml/scripts/run-ocaml.sh \
         tests/smoke/ocaml_hello.ml' \
     --desc 'sw-cor24-ocaml wiring smoke — prints 42'
   ```
   Run `reg-rs run -p tuplet_ocaml_smoke` to confirm pass.
5. Document the invocation and the reg-rs test name in
   `docs/tooling-smoke.md` so the next session knows how to re-run.

## If blocked

If `sw-cor24-ocaml` cannot run a hello-world for any reason (build
broken, missing dependency, missing feature), **do not patch the
upstream repo**. Instead:

1. File a GitHub issue against `sw-embed/sw-cor24-ocaml` via
   `gh issue create --repo sw-embed/sw-cor24-ocaml` describing the
   failure and the exact command you ran.
2. Record the issue number in `docs/tooling-smoke.md` under a
   `Blocked` section.
3. Run `agentrail abort --reason "blocked on sw-embed/sw-cor24-ocaml#<n>"`
   to mark the step blocked and stop.

## Do not

- Do not edit any file under `~/github/sw-embed/sw-cor24-ocaml`.
- Do not stash a workaround in the Tuplet repo.

## Finish (on success)

- Commit the sample `.ml` file, `docs/tooling-smoke.md`, and
  `.agentrail/` updates.
- `agentrail complete --summary "sw-cor24-ocaml wiring verified;
  reg-rs baseline captured" --reward 1 --actions "ran hello-world
  and created reg-rs test"`.
