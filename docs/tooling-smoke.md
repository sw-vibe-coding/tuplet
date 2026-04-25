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

- `*.rgt` -- test definition + golden baseline output.

Gitignored (transient):

- `*.tdb` -- legacy db format.
- `*.tdb.lock` -- concurrency lock.
- `*.out` -- latest run output.

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

### tuplet_forth_smoke

Not yet created. Covered by the next saga step (`forth-smoke-test`).

## Blocked

(None currently. If `sw-cor24-ocaml` or `sw-cor24-forth` breaks in a
way that prevents a smoke test from passing, file an issue at
`sw-embed/sw-cor24-ocaml` / `sw-embed/sw-cor24-forth` and record the
issue number here.)
