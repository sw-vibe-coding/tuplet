# Step: parser-saga-exit-audit

Audit the tuplet-parser saga against docs/plan.md exit criteria before moving to tuplet-checker.

Scope:
- Compare implemented parser behavior and regressions against saga 2 exit criteria in docs/plan.md.
- Identify any remaining parser gaps that block checker entrance, especially tuple-shaped AST expectations, syntax declaration shape, and deterministic error dumps.
- Add only small missing parser regressions/docs if needed; do not start checker implementation.
- If parser saga is complete enough, mark it done or prepare a final parser cleanup step.

Finish:
- Clear written summary of remaining parser gaps or confirmation that checker can start.
- Relevant regressions pass.
- Commit Tuplet repo changes only.