# Step: bootstrap-commit

Commit the untracked seed files so the project has a tracked baseline
on `main`.

## Scope

- `CLAUDE.md` (agentrail agent instructions)
- `COPYRIGHT`
- `LICENSE`
- `README.md` (currently empty — leave as-is or add a one-line
  placeholder referencing `docs/`; do not write full docs yet, that is
  a later step)
- `docs/` (seed docs: `ai_agent_instructions.md`, `process.md`,
  `tools.md`, `research.txt`)
- `.agentrail/` (saga + plan created by `agentrail init`)

## Do

1. `git add` the above paths.
2. Commit with a short message like `chore: seed project docs and
   agentrail saga`. Include `Co-Authored-By: Claude ...` per
   project convention. Do not push.
3. Verify `git status` is clean of unknown files relevant to this
   step (there may be step prompt files under `.agentrail/steps/` —
   include them).

## Do not

- Do not write `README.md` content or new docs in this step.
- Do not edit any seed doc's content.
- Do not push.

## Finish

- `git commit`, then `agentrail complete --summary "committed seed
  docs and agentrail saga" --reward 1 --actions "git add, git
  commit"`.
