# Cloud + Data + Portfolio (7 Projects)

This monorepo contains seven industry-agnostic, high-value portfolio projects demonstrating cloud engineering, data engineering, automation, ML, and agentic workflows.

## Repo layout
Each project lives in `project-0X-.../` and contains `src/`, `diagrams/`, `README.md` and other resources.

## How this repo is built
- Use atomic, descriptive commits (Conventional Commits).
- Keep verified diagrams in `*/diagrams/*.drawio` and exports in `*/diagrams/exported/` (PNG/SVG).
- Use branches per feature: `feature/<short-desc>` or `chore/infra-setup`.

## Tools & workflow included
- `scripts/atomic_commit.sh` — helper for atomic commits
- `scripts/create_diagram_entry.sh` — helper to add diagram placeholders and export policy
- `hooks/` — sample git hooks (commit-msg enforcement)

## Next steps
1. Fill project READMEs (templates are already present).
2. Implement code incrementally with small atomic commits.
3. Add diagrams using draw.io and export PNG/SVG to `diagrams/exported/`.

