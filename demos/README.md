# Tuplet Demos

**Status:** aspirational. None of these run yet -- the Tuplet
compiler does not exist past the lexer. They document the
intended language UX and serve as test fixtures for future
sagas.

The PoC's actual demonstration is `dowhile.tup` (see
`docs/poc-goals.md`); the rest project beyond it.

## Index

| File             | Demonstrates                                    | Saga it lights up |
|------------------|-------------------------------------------------|-------------------|
| `dowhile.tup`    | User-minted `do..while` (the PoC milestone).    | tuplet-forth-emit |
| `coord2.tup`     | Tuple-var declaration + destructuring.          | tuplet-parser     |
| `divmod.tup`     | Multi-output verb (`div2` returns quotient + remainder). | tuplet-forth-emit |
| `factorial.tup`  | Recursive user-defined verb.                    | tuplet-forth-emit |
| `power.tup`      | Two power variants; one with `assert`.          | post-prelude      |
| `plot_splice.tup`| Call-site splicing of a 2-arity tuple.          | tuplet-checker    |
| `result_handle.tup` | `Ok`/`Err` constructors + `handle..end`.    | post-prelude (layer 4) |
| `pipeline.tup`   | User-minted forward pipe `|>`.                  | post-prelude (layer 6) |

## Running (someday)

When the compiler exists:

```
tuplet run demos/<name>.tup
```

The `tuplet-demos` saga (final phase per `docs/plan.md`) is
where these are wired up to reg-rs baselines and proven to run
through the full lex-parse-check-ir-emit-cor24-run pipeline.

A negative test in that saga removes `lib/std.tup` and
verifies that representative demos fail to parse -- proving
the prelude is genuinely load-bearing rather than duplicated
in the compiler.
