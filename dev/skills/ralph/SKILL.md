---
name: ralph
description: AFK implementation loop — reads open GitHub issues labeled `afk`, implements each using TDD, commits, pushes, and closes issues until no tasks remain. Use when the user wants to walk away and let the agent implement a backlog autonomously.
---

# Ralph

Ralph runs an AFK loop: it picks up open GitHub issues labeled `afk`, implements each one using test-driven development, commits, pushes, and closes the issue — then repeats until no tasks remain.

## Usage

```
/dev:ralph [--agent claude|opencode] [--branch <name>] [--issues <file>] [--iterations <n>]
```

**Flags:**
- `--agent`: Agent to use. `claude` (default) or `opencode`.
- `--branch`: Create and switch to this branch before starting. Errors if branch already exists.
- `--issues`: Path to a local markdown file of issues (for projects without GitHub). Must use the same body format as GitHub issues.
- `--iterations`: Cap the number of iterations (default: unlimited, runs until NO MORE TASKS).

## What it does

1. Checks out `--branch` if specified
2. Loops until no `afk`-labeled issues remain:
   - Fetches open issues (GitHub or local file)
   - Fetches last 5 commits for context
   - Auto-detects test and typecheck commands
   - Invokes the agent with the ralph prompt
   - After each commit: `git push`
3. Exits cleanly when the agent signals `<promise>NO MORE TASKS</promise>`

## Invocation

When the user runs `/dev:ralph`, execute:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/ralph.sh" <flags>
```

Pass through all flags from the user's invocation verbatim. Do not modify or interpret the flags — let ralph.sh handle them.

## Requirements

- `gh` CLI authenticated to the repo
- `git` initialized with a remote
- Claude Code CLI (`claude`) in PATH for `--agent claude`
- `opencode` in PATH for `--agent opencode`

## Notes

- Issues must be labeled `afk` via `/dev:to-issues` before ralph can pick them up.
- `ralph.config.json` at the repo root overrides auto-detected test commands (fields: `testCmd`, `typecheckCmd`).
- OpenCode headless mode (`--agent opencode`) is best-effort — verify it supports non-interactive invocation before relying on it.
