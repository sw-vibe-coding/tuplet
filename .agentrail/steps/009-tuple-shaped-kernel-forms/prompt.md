# Step: tuple-shaped-kernel-forms

Evolve parser scaffolding toward the tuple-first AST contract by recognizing tuple signatures and tuple-pattern assignment shapes in parser token streams.

Scope:
- Preserve existing parser dump compatibility for current regressions unless a new regression explicitly covers the new shape.
- Add deterministic AST dumps for tuple variable signature declarations like *coord2 -> (x y).
- Add deterministic AST dumps for tuple-pattern assignment like a, b <- coord2.
- Keep checker, IR, interpreter, and Forth emission out of scope.
- Add focused parser smoke drivers and reg-rs baselines.
- Update parser docs and AgentRail summary.

Finish:
- Relevant parser regressions pass.
- Existing memory handoff regressions still pass.
- Commit the Tuplet repo changes only.