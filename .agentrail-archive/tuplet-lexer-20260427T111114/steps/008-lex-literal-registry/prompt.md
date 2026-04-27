# Step: lex-literal-registry

Add a runtime literal registry that the parser can extend while processing
`*syntax` declarations. The lexer needs a `Lexer.add_literal`-style function
that registers a byte-string name; subsequent identifier lexing compares
completed identifiers against the registry and emits `TLiteral name` instead
of `TIdent name` for matches.

## Scope

- Add a registered-literals collection using the host-supported mutable reference mechanism, or the closest existing local pattern.
- Add an `add_literal` function that records a literal name.
- Update identifier completion so registered names become literal tokens while unregistered names remain identifiers.
- Preserve existing identifier behavior: ASCII letters start identifiers; letters, digits, and `_` continue; trailing `?` is allowed once at the end; bare `_` remains `TUnderscore`.
- Add focused fixtures and reg-rs baselines for registered vs unregistered identifiers.
- Document the parser/lexer contract in `docs/lexer.md`.

## Out of scope

- Parsing `*syntax` declarations.
- Parser AST or semantics.
- User-defined Unicode glyph templates beyond the current kernel aliases.

## Finish

Stage `src/lexer.ml`, new fixtures, `work/reg-rs/`, `docs/lexer.md`, and the full `.agentrail/` delta. Commit, push, then complete the step.
