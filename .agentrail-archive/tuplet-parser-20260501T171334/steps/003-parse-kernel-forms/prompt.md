# Step: parse-kernel-forms

Evolve the flat token-stream parser into a small kernel-form parser that recognizes the hard-coded forms needed before syntax template expansion.

## Scope

- Keep source split across ast/parser drivers.
- Add AST variants and dumps for kernel statements instead of only one-token STMT nodes.
- Parse comments as trivia and EOF as program terminator.
- Recognize simple assignment shape using TLArrow, mint-prefixed statements using TMint, parenthesized token groups, brace token groups, comma separators, and underscore slots as structured AST nodes.
- Recognize a syntax declaration head from TMint followed by ident:syntax and split template versus expansion around ident/literal expand, but do not register or apply templates yet.
- Add deterministic success and error baselines under work/reg-rs/tuplet_parse_*.
- Update docs/parser.md with the kernel-form AST contract.

## Out of scope

- Syntax registry mutation.
- Longest-match template expansion.
- Checker, IR, interpreter, Forth emission.

## Finish

Run parser baselines, relevant lexer smoke checks, markdown-checker for changed docs, stage source/docs/baselines/.agentrail, commit, push, complete with the next parser step.
