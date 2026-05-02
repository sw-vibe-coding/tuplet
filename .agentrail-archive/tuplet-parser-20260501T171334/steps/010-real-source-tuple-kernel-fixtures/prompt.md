# Step: real-source-tuple-kernel-fixtures

Feed the tuple-shaped kernel forms through the real lexer/bridge/memory-backed source path.

Scope:
- Add memory-backed fixtures for *coord2 -> (x y) and a, b <- coord2.
- Add small drivers or reuse existing memory parser path so lexer tokens flow through Lex_bridge into Parser.
- Add reg-rs baselines for the real-source AST dumps.
- Preserve existing parser-only and memory handoff regressions.
- Keep checker/IR/emitter out of scope.

Finish:
- Real-source tuple signature and tuple-pattern assignment regressions pass.
- Parser docs and AgentRail summary mention the memory-backed coverage.
- Commit Tuplet repo changes only.