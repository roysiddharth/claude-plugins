# dev-plugin

A Claude Code plugin for AI-assisted development workflows: plan, spec, break into issues, and implement AFK.

The full loop looks like:

```
/dev:grill-me   →   /dev:to-prd   →   /dev:to-issues   →   ralph
```

---

## Install

```bash
claude plugin marketplace add github.com/roysiddharth/dev-plugin --scope user
claude plugin install dev --scope user
```

Then add the `ralph` alias to your shell:

```bash
echo 'alias ralph="bash $(ls ~/.claude/plugins/cache/roysiddharth/dev/*/scripts/ralph.sh 2>/dev/null | tail -1)"' >> ~/.zshrc
```

Restart your shell or run `source ~/.zshrc` after.

---

## Skills

| Skill | Invoke | What it does |
|-------|--------|--------------|
| grill-me | `/dev:grill-me` | Interviews you relentlessly about a plan or design. Resolves every branch of the decision tree before letting you proceed. |
| to-prd | `/dev:to-prd` | Synthesizes the current conversation into a structured PRD. Saves it to the codebase. |
| to-issues | `/dev:to-issues` | Breaks a PRD or plan into independently-grabbable GitHub issues using vertical tracer-bullet slices. Labels each `afk` or `hitl`. |
| tdd | `/dev:tdd` | Test-driven development with red-green-refactor. One behavior at a time, integration-style tests only. |

## Scripts

| Script | Invoke | What it does |
|--------|--------|--------------|
| ralph | `ralph` | AFK implementation loop. Picks up `afk`-labeled issues, implements with TDD, commits, pushes, and closes until the backlog is empty. |

---

## Usage

### Full workflow

```bash
# 1. Stress-test your plan
/dev:grill-me

# 2. Turn the resolved plan into a PRD
/dev:to-prd

# 3. Break the PRD into GitHub issues
/dev:to-issues

# 4. Walk away — ralph implements the backlog
ralph
```

### ralph flags

```
ralph [--agent claude|opencode] [--branch <name>] [--issues <file>] [--iterations <n>]
```

| Flag | Default | Description |
|------|---------|-------------|
| `--agent` | `claude` | Agent to use: `claude` or `opencode` |
| `--branch` | _(none)_ | Create and switch to this branch before starting |
| `--issues` | _(none)_ | Path to a local markdown file of issues (no GitHub required) |
| `--iterations` | unlimited | Cap the number of iterations |

### Per-project override

Place a `ralph.config.json` in your repo root to override auto-detected test commands:

```json
{
  "testCmd": "bun run test",
  "typecheckCmd": "bun run typecheck"
}
```

If this file is present, auto-detection is skipped entirely.

---

## Requirements

- [`gh`](https://cli.github.com/) CLI, authenticated to the repo
- `git` initialized with a remote
- `python3` in PATH
- `claude` CLI in PATH (for `--agent claude`)
- `opencode` in PATH (for `--agent opencode`)

---

## License

MIT
