# Step: forth-smoke-test

Prove that the `sw-cor24-forth` toolchain at
`~/github/sw-embed/sw-cor24-forth` can run a Forth program end-to-
end on this machine, and capture a `reg-rs` baseline inside THIS
repo.

## Scope

Wiring confidence only. Program under test is a trivial Forth
snippet that prints a known output to UART (e.g., `.( HELLO)` or
`65 EMIT` to print `A`).

## Do

1. Read `~/github/sw-embed/sw-cor24-forth/CLAUDE.md` and
   `README.md` for the canonical invocation, which uses `cor24-run
   --run forth.s -u '<input>\n' --speed 0 -n 5000000`.
2. From the existing `~/github/sw-embed/sw-cor24-forth/forth.s`,
   identify the smallest UART input that produces a deterministic
   printed output. Options:
   - Feed a numeric word: `42 .\n` — should print `42 `.
   - Feed `65 EMIT\n` — should print `A`.
3. Create `tests/smoke/forth_hello.input` in THIS repo containing
   the chosen input line (UNIX LF terminator).
4. Register a `reg-rs` test named `tuplet_forth_smoke`:
   ```
   PP="grep -A 100 '^UART output:' || true"
   reg-rs create -t tuplet_forth_smoke -P "$PP" --timeout 30 \
     -c "cor24-run --run ~/github/sw-embed/sw-cor24-forth/forth.s \
         -u \"$(cat tests/smoke/forth_hello.input)\" \
         --speed 0 -n 5000000 2>&1" \
     --desc 'sw-cor24-forth wiring smoke'
   reg-rs run -p tuplet_forth_smoke
   ```
5. Append the invocation and reg-rs test name to
   `docs/tooling-smoke.md` (created in the previous step).

## If blocked

If `sw-cor24-forth` cannot produce the expected output (bug, broken
binary, missing feature needed even for this trivial case), **do
not patch upstream**:

1. `gh issue create --repo sw-embed/sw-cor24-forth` with a
   minimal reproducer.
2. Record the issue number in `docs/tooling-smoke.md` under
   `Blocked`.
3. `agentrail abort --reason "blocked on sw-embed/sw-cor24-forth#<n>"`.

## Do not

- Do not edit any file under `~/github/sw-embed/sw-cor24-forth`.
- Do not work around upstream bugs in this repo.

## Finish (on success)

- Commit the input file, `docs/tooling-smoke.md` update, and
  `.agentrail/` files.
- `agentrail complete --summary "sw-cor24-forth wiring verified;
  reg-rs baseline captured" --reward 1 --actions "ran Forth hello
  and created reg-rs test"`.

## Suggested next step

On completion, propose next step `ast-ir-sketch` with prompt
covering `docs/design.md` (AST types, IR instruction set, builtin
verbs), drawing on `docs/research.txt` lines ~2960–3050.
