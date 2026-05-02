# DSL Examples -- What Users Can Build with Tuplet

These are aspirational examples of language extensions a DSL
author might mint *in Tuplet itself*, after the PoC kernel +
prelude exist. They are not part of the PoC scope; they are the
**reason** the PoC scope is what it is. If the mechanism the
PoC demonstrates can't grow into supporting these, the design
is wrong.

The PoC ships only the mechanism (`▪syntax T expand E`, with
ASCII fallback `*syntax T expand E`) and one
small witness (`do..while`); these examples show how far the
mechanism is meant to scale.

## Example: user-minted conditional family

```
# Standard if/then/else, minted in lib/std.tup (NOT in the kernel)
▪syntax if _ then _ else _ end expand
  _1  prim/forth "IF"  _2  prim/forth "ELSE"  _3  prim/forth "THEN"

# Approximate-equal conditional with absolute tolerance
▪syntax if-approx _ approx _ within _ then _ else _ end expand
  _1 _2 - abs _3 < if _4 else _5 end

# Approximate-equal with percent tolerance
▪syntax if-approx-pct _ approx _ within _ pct then _ else _ end expand
  _1 _2 - abs _2 _3 * 100 div < if _4 else _5 end

# Tail-conditional postfix form (math style)
▪syntax _ if _ else _ expand
  _2  prim/forth "IF"  _1  prim/forth "ELSE"  _3  prim/forth "THEN"
```

Use sites:

```
classify ⟵ if-approx 10 approx 12 within 3 then close else far end   # -> close
classify ⟵ if-approx-pct 100 approx 110 within 5 pct then close else far end   # -> far

# Tail conditional, math style
result ⟵ N^E if E >= 0 else 0
```

## Example: user-defined verb with body

```
# Math-style curried definition
▪ Power N E := N^E if E >= 0 else 0

# Standard signature-with-body form
▪power ⎛n e⎠ ───‣ ⎛p⎠ ⟵ power-body
  # body uses minted control flow: do..times etc.
```

## Example: structured-block iteration (3-piece delimiter)

```
# A loop construct minted in the prelude. The `{ ... | ... | ... }`
# form has three pieces: init / count / step. Modeled on Forth's
# DO-LOOP idiom.
▪syntax { _ | _ | _ } expand
  _1  prim/forth "0"  _2  prim/forth "DO"  _3  prim/forth "LOOP"

# Use site: power = N^E
▪power ⎛N E⎠ ───‣ ⎛P⎠ ⟵ { 1 | E | N * }
```

(The Unicode form would use the long curly-bracket-hook glyphs
U+23A7 / U+23A8 / U+23A9 / U+23AB rather than ASCII pipes; the
ASCII form here is a placeholder.)

## What features these examples imply

Each row is a feature the spec touches and a status note. None
of these are PoC scope; this is the roadmap for after the PoC
demonstrates the mechanism.

| Feature                                | Used in              | Status                              |
|----------------------------------------|----------------------|-------------------------------------|
| `▪syntax T expand E` declaration       | every example        | **PoC scope** -- already specified  |
| `▪name p1 p2 := body` (curried def)    | `Power N E := ...`   | not specified -- needs new form     |
| `▪name⎛args⎠ ───‣ ⎛outs⎠ ⟵ body`       | `▪power ⎛N E⎠ ...`   | partly specified in `docs/grammar.md` example 5 |
| Unicode in identifiers (Greek, math)   | `if<U+2248>`, `<U+03B1>`, `<U+03C1>` | not specified -- needs lexer extension |
| Hyphens in identifiers                 | `if-close?`          | not specified -- needs lexer rule   |
| `:=` definitional vs `⟵` assignment    | `Power N E := ...`   | not specified -- decide if synonym  |
| Tail conditional `_ if _ else _`       | `N^E if E >= 0 ...`  | mintable as `▪syntax`               |
| Approximate-equal operator `~~` / U+2248 | `a ~~ b`           | mintable                            |
| Tolerance binder `+/-` / U+00B1        | `a ~~ b +/- e`       | mintable                            |
| Type annotations `n : Int` / U+2124    | `(n : Z)`            | not in PoC; future saga             |
| Three-piece block `{ _ \| _ \| _ }`    | power body           | mintable                            |
| Test-arrow `->>` / U+2192              | `Power 2 10 ->> 1024`| mintable as a top-level assertion form |
| Runtime assertion / guard              | `iff e is positive`  | needs runtime assert primitive (`prim/forth "ABORT"`) |
| Exponentiation `^`                     | `N^E`                | mintable as `▪syntax _ ^ _ expand ...` |

## Open design questions

The examples surface real choices that haven't been made yet.
Listing them so they're not silently picked by the parser
implementation:

1. **`if/then/else` location: kernel or prelude?**
   Current spec puts it in `lib/std.tup` (prelude). The user's
   note "I want to be able to mint if/then/else" confirms this:
   even `if/then/else` is library, not language. **Decision:
   no change; `if/then/else` stays in the prelude.**

2. **`:=` vs `⟵`: distinct operators or synonyms?**
   `⟵` is ordinary assignment to an existing name (the kernel
   form). `:=` is used in math-style definitions (`Power N E
   := ...`). Two reasonable options:
   - (a) Synonyms; document `:=` as a Unicode-friendly alias.
   - (b) Distinct: `⟵` is "store now," `:=` is "bind name to
     expression / verb body" (definitional, like Coq's `Definition`).
   **Awaiting decision.**

3. **Curried `▪name p1 p2 := body` form:**
   This is a third declaration form, distinct from the existing
   `▪name ───‣ ⎛outs⎠` (tuple-var) and
   `▪name⎛ins⎠ ───‣ ⎛outs⎠ ⟵ body`
   (verb signature with body). Is it sugar for the explicit form,
   or a peer? **Awaiting decision.**

4. **Unicode and hyphen in identifiers:**
   Currently, identifiers are `[A-Za-z][A-Za-z0-9_]*\??`.
   Examples need:
   - Greek letters and math glyphs in the middle of identifiers
     (e.g. `if<U+2248>`).
   - Hyphen-minus inside identifiers (e.g. `if-close?`).
   Both are pure lexer extensions. **Likely both yes**, but each
   requires careful disambiguation (hyphen vs subtraction).
   **Awaiting decision.**

5. **Type annotations `n : Z`:**
   The PoC has no type system. Annotations like `(n : Z e : Z)`
   are decorative for the PoC at most. Either reject them at the
   parser (PoC), or accept-and-discard. **Decision: reject in
   PoC; queue for a future typing saga.**

6. **Three-piece block `{ _ | _ | _ }`:**
   Two-piece blocks `{ _ }` are anonymous-verb literals (kernel).
   Three-piece blocks could be:
   - (a) Mintable as a `▪syntax` declaration (preferred -- stays
     consistent with the everything-is-extensions principle).
   - (b) A new kernel form.
   **Decision pending; preference (a).**

7. **Test-arrow / assertion form `->>` / U+2192:**
   `Power 2 10 ->> 1024` is a test assertion. Mintable as a
   `▪syntax expr ->> expected expand ...` that compiles to "run
   expr, compare, abort if mismatch, otherwise continue."
   **Mintable; not PoC scope.**

8. **Runtime assertions:**
   `Power 5 -3 ->> assertion failed` requires a runtime ABORT
   (which `sw-cor24-forth` provides via `QUIT` / `ABORT`).
   Wrap as `prim/forth "ABORT"` in a new prelude verb `assert`.
   **Mintable once the prelude exists.**

## What the PoC actually proves

The PoC's `do..while` demo is a **two-slot** `▪syntax`
declaration with `expand`. That is the same mechanism as every
example in this file. If `do..while` works end-to-end (REPL +
emit + run + reg-rs baseline), the mechanism is proven; the
examples in this file are then "just more `▪syntax`
declarations" to write in the prelude saga and beyond.

The PoC milestone explicitly DOES NOT ship:

- `if/then/else` (prelude saga 7)
- Any of the conditional families above
- Curried `:=` definitions
- Unicode identifiers
- Hyphenated identifiers
- Type annotations
- Three-piece blocks
- Test-arrow assertions

It does ship: the mechanism that lets a user write all of those
in `lib/std.tup` or in their own files, without ever touching
the compiler.

## Reference

- `docs/poc-goals.md` -- the PoC milestone scope.
- `docs/kernel.md` -- the kernel/prelude split: what is and
  isn't mintable.
- `docs/grammar.md` -- current surface grammar (subset of what
  these examples eventually need).
- `docs/plan.md` -- the saga arc; sagas 7 (prelude) and 8
  (demos) absorb most of this file's examples.
