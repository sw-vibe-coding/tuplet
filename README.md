# tuplet

An experimental infix programming language with first-class
named tuple bundles, multi-output verbs, and call-site
argument splicing -- compiled to Forth and executed on the
COR24 runtime.

![tuplet logo](images/tuplet-logo.jpg)

## What's special

Tuplet's distinguishing feature is that **almost everything
is user-extensible**. The kernel is ~10 forms; everything
else (`if/then/else`, `while`, every operator, every helper)
lives in `lib/std.tup` as a `▪syntax` declaration that
ordinary Tuplet users can read, replace, or write more of.

The single mechanism is **mint** (`▪`, with `*` as an ASCII
fallback):

```
▪syntax do _ while _ end expand
  prim/forth "BEGIN"  _1  _2  prim/forth "0= UNTIL"

▪n ⟵ 0
do
  n ⟵ n + 1
  n prim/forth "."
  prim/forth "SPACE"
while  n < 3  end
# 1 2 3
```

The user writes that, the language extends. No compiler
change.

## Status

Phase 0 (scaffold) and the early steps of Phase 1 (lexer)
are complete. The interpreter, IR, Forth emitter, prelude,
and demo gallery are upcoming sagas. See `docs/plan.md` for
the arc and `docs/poc-goals.md` for the demo target.

## Documentation

- [`docs/poc-goals.md`](docs/poc-goals.md) -- the single
  demoable target.
- [`docs/prd.md`](docs/prd.md) -- product requirements.
- [`docs/grammar.md`](docs/grammar.md) -- surface syntax.
- [`docs/notation.md`](docs/notation.md) -- authoritative glyphs.
- [`docs/kernel.md`](docs/kernel.md) -- the kernel/prelude
  boundary.
- [`docs/design.md`](docs/design.md) -- AST and stack IR.
- [`docs/lowering.md`](docs/lowering.md) -- IR -> Forth.
- [`docs/lexer.md`](docs/lexer.md) -- lexer host notes.
- [`docs/plan.md`](docs/plan.md) -- saga arc.
- [`docs/dsl-examples.md`](docs/dsl-examples.md) -- DSL
  extensions a user might write.
- [`docs/language-wishlist.md`](docs/language-wishlist.md) --
  layered preludes, error handling, modules; design research
  for what comes after the PoC.
- [`docs/tooling-smoke.md`](docs/tooling-smoke.md) -- how to
  rerun the wiring-confidence tests.
- [`docs/glyphs.md`](docs/glyphs.md) -- the alphabet of
  Tuplet glyphs (minimal + suggested).
- [`docs/emacs-inputs.md`](docs/emacs-inputs.md) -- entering
  Tuplet glyphs in Emacs (TeX, Agda, custom Quail).
- [`docs/cli-inputs.md`](docs/cli-inputs.md) -- entering
  glyphs anywhere via Espanso, XCompose, AHK, etc.
- [`demos/`](demos/) -- aspirational `.tup` examples.

## Project layout

```
src/                Tuplet host code (OCaml subset on sw-cor24-ocaml)
tests/              Test fixtures + reg-rs inputs
work/reg-rs/        Golden baselines (.rgt + .out tracked)
docs/               Specs, design, wishlist
demos/              Aspirational .tup programs
scripts/            Build/run helpers
images/             Logo
.agentrail/         Saga / step durable record
```

## Related projects

- [sw-cor24-ocaml](https://github.com/sw-embed/sw-cor24-ocaml)
  -- the OCaml subset interpreter that hosts Tuplet's parser.
- [sw-cor24-forth](https://github.com/sw-embed/sw-cor24-forth)
  -- the DTC Forth runtime Tuplet compiles to.
- [sw-cor24-emulator](https://github.com/sw-embed/sw-cor24-emulator)
  -- the COR24 emulator (`cor24-run`) that executes both.

## Links

- Blog: [Software Wrighter Lab](https://software-wrighter-lab.github.io/)
- Discord: [Join the community](https://discord.com/invite/Ctzk5uHggZ)
- YouTube: [Software Wrighter](https://www.youtube.com/@SoftwareWrighter)

## Copyright

Copyright (c) 2026 Michael A. Wright

## License

MIT. (C) 2026 Michael A Wright. See [LICENSE](LICENSE).
