# Tooling Smoke Tests

Small, stable tests that prove the upstream toolchains Tuplet depends
on are actually wired up on this machine. They do not exercise any
Tuplet functionality -- they only catch "the interpreter won't even
start" class of breakage.

## Running everything

```
REG_RS_DATA_DIR=work/reg-rs reg-rs run -p tuplet_
```

The `tuplet_` prefix matches all Tuplet smoke tests. All must pass
before starting any compiler work in a fresh session.

## Baselines location

reg-rs test databases live in `work/reg-rs/`. Committed files:

- `*.rgt` -- test definition (command, timeout, preprocess, desc).
- `*.out` -- captured run output; the golden baseline that `.rgt`
  compares against on re-run. Both are needed on a fresh clone
  for tests to have a baseline without re-running.

Gitignored (transient):

- `*.tdb` -- reg-rs internal state (regenerated on run).
- `*.lock` -- concurrency lock.

## Rebasing

If an upstream tool changes its output format intentionally, rebase
the baseline:

```
REG_RS_DATA_DIR=work/reg-rs reg-rs rebase -p <test-name>
```

Only rebase after confirming the change is wanted, not a regression.

## Tests

### tuplet_ocaml_smoke

Proves the `sw-cor24-ocaml` toolchain can run a trivial `.ml` file
end-to-end.

- Source: `tests/smoke/ocaml_hello.ml`
  -- body `let x = 41 + 1 in print_int x`
- Expected output: `42` (preceded by the Pascal runtime's source
  echo, which is captured in the baseline).

Invocation:

```
bash ~/github/sw-embed/sw-cor24-ocaml/scripts/run-ocaml.sh \
     /Users/mike/github/sw-vibe-coding/tuplet/tests/smoke/ocaml_hello.ml
```

Re-run:

```
REG_RS_DATA_DIR=work/reg-rs reg-rs run -p tuplet_ocaml_smoke
```

### tuplet_forth_noname_smoke

Proves the `:NONAME` primitive (added in `sw-embed/sw-cor24-forth#5`,
commit `ff7b43d`) works on this machine. The Tuplet emitter's
anonymous-verb path (mechanism 2 in `docs/kernel.md`) depends on
this primitive.

- Source: `tests/smoke/forth_noname.input` -- `:NONAME 65 EMIT 10
  EMIT ; EXECUTE`.
- Expected output (post-preprocess): `UART output: A` then a
  newline, then ` ok`.

Re-run:

```
REG_RS_DATA_DIR=work/reg-rs reg-rs run -p tuplet_forth_noname_smoke
```

### tuplet_forth_smoke

Proves the `sw-cor24-forth` toolchain runs a Forth program end-to-
end on the COR24 emulator.

- Source: `tests/smoke/forth_hello.input` -- `65 EMIT\n`.
- Expected output (after preprocess): `UART output: A ok` plus
  emulator summary lines.

The reg-rs preprocess filter keeps only the lines from `UART
output:` forward, so per-instruction UART RX/TX trace lines (which
can shift with emulator version) don't break the baseline.

Invocation:

```
PP="grep -A 100 '^UART output:' || true"
cor24-run --run ~/github/sw-embed/sw-cor24-forth/forth.s \
  -u "$(cat tests/smoke/forth_hello.input)" \
  --speed 0 -n 5000000 2>&1 | eval "$PP"
```

Re-run:

```
REG_RS_DATA_DIR=work/reg-rs reg-rs run -p tuplet_forth_smoke
```

## Blocked

(None currently. If `sw-cor24-ocaml` or `sw-cor24-forth` breaks in a
way that prevents a smoke test from passing, file an issue at
`sw-embed/sw-cor24-ocaml` / `sw-embed/sw-cor24-forth` and record the
issue number here.)
