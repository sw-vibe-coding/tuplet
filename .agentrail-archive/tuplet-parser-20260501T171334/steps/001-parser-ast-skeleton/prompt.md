# Step: parser-ast-skeleton

Create the minimum parser saga skeleton: AST token-consumer scaffolding and deterministic AST dump plumbing, without implementing full grammar yet.

## Scope

- Add parser-facing AST types in src/ast.ml or the smallest local equivalent.
- Add src/parser.ml with a minimal entry point that can consume the existing lexer dump/token shape or a small test-only token source, following current repo patterns.
- Add a deterministic AST dump format for the initial skeleton.
- Add a parser smoke fixture and reg-rs baseline under work/reg-rs/tuplet_parse_*.
- Document the parser skeleton and intended token handoff briefly in docs/parser.md.

## Constraints

- Do not implement template matching yet.
- Do not implement checker, IR, interpreter, or Forth emission.
- Keep this step small and focused on establishing files, run path, and dump format.
- Preserve lexer behavior and lexer baselines.

## Finish

- Run the new parser baseline and relevant smoke checks.
- Run markdown-checker for changed markdown.
- Stage parser source, docs/parser.md, parser fixtures/baselines, and the full .agentrail/ delta.
- Commit, push, then complete the step with the next parser step planned.
