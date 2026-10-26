# Memory index

This directory is the project's memory store, committed to git so it is versioned and visible to the maintainer, to teammates and to every agent working here. `.claude/memory` is a symlink to it.

Convention:

- One markdown file per project-scoped fact worth remembering: decisions, constraints, gotchas, and context that cannot be derived from the code or the git history.
- Each file gets a one-line entry in this index: `- [Title](file.md) — one-line hook`.
- Update or delete memory files that turn out to be wrong rather than leaving stale ones, and keep this index in step.

This directory replaces any native or global memory feature for this project (Claude Code's `~/.claude/projects/<project>/memory/`, Cursor memories, or similar). Do not save project-scoped memories there; write them here.

## Memories

