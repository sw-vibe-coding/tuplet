# Step: syntax-registry-skeleton

Add the first parser-owned syntax registry skeleton and register syntax declaration templates without applying them yet.

## Scope

- Add src/registry.ml or the smallest equivalent registry module/source file.
- Store syntax declaration entries parsed from `STMT   syntax-expand` and `STMT   syntax-verb` shapes: declaration order, template item strings, expansion item strings, and mode.
- Add parser plumbing that returns or dumps registered templates deterministically after parsing a syntax declaration stream.
- Preserve existing kernel-form AST dumps and parser error behavior.
- Add reg-rs baselines under work/reg-rs/tuplet_parse_* for at least one expand-form registration and one -> verb-form registration.
- Update docs/parser.md with the registry storage contract.

## Out of scope

- Applying registered templates to later input.
- Longest-match matching.
- Checker, IR, interpreter, Forth emission.

## Finish

Run parser baselines, relevant lexer smoke checks, markdown-checker for changed docs, stage source/docs/baselines/.agentrail, commit, push, complete with the next parser step.
