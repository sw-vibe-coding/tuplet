# Step: parse-kernel-token-stream

Replace the parser skeleton fixed sample token source with a small token-stream parser over the lexer-facing token type. Implement enough kernel parsing to recognize a flat program of token statements and comments deterministically, but do not implement syntax template matching yet.

## Scope

- Keep AST and parser source split from the skeleton.
- Add parser functions that consume token lists with explicit remaining-token threading.
- Parse comments as skipped trivia and EOF as program terminator.
- Add deterministic success and error AST/error dumps for simple kernel token streams.
- Add reg-rs baselines under work/reg-rs/tuplet_parse_*.
- Update docs/parser.md with the token-stream contract.

## Out of scope

- Syntax registry and template expansion.
- Checker, IR, interpreter, Forth emission.

## Finish

Run parser baselines, relevant lexer smoke checks, markdown-checker for changed docs, stage source/docs/baselines/.agentrail, commit, push, complete with the next parser step.
