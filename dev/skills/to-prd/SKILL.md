---
name: to-prd
description: Use this skill when the user wants to turn the current conversation context into a Product Requirements Document (PRD). Triggers include phrases like "write a PRD", "create a PRD", "turn this into a PRD", "make a PRD", "/to-prd". Synthesizes conversation context and codebase understanding into a structured PRD, then optionally posts it as a GitHub issue if the project is a git repository.
---

You are writing a PRD from the current conversation context and codebase understanding. Do NOT interview the user — synthesize what you already know.

## Process

### Step 1 — Understand the codebase

If you have not already explored the repo in this conversation, use the Explore subagent to understand the current state: key modules, architecture, and what would need to change.

Skip this step if you already have sufficient codebase context from the conversation.

### Step 2 — Identify modules

Sketch the major modules that will need to be built or modified to complete the implementation. Look for opportunities to identify deep modules: ones that encapsulate significant functionality behind a simple, stable interface.

Present this module sketch to the user and confirm it matches their expectations before proceeding.

### Step 3 — Write the PRD

Use the template in `./prd-template.md` to produce a complete PRD. Fill in every section with specific, concrete content derived from the conversation and codebase.

**Testing Decisions section:** Identify which modules and public interfaces warrant testing. Describe the key behaviors (not implementation steps) that tests should verify — these become the starting behavior list if the session uses `/tdd`. Do not commit to writing tests otherwise — per project policy, tests are written only when `/tdd` is invoked or explicitly requested.

### Step 4 — Save to codebase

Save the PRD as a `.md` file in the codebase:

- If the PRD covers a specific module or feature, place it inside that module's directory alongside the implementation.
- If the PRD applies to the whole project, place it in the root `docs/` folder.

Use a clear, descriptive filename (e.g. `auth-redesign-prd.md`). Do not use numeric prefixes unless ordering truly matters.

## Output Format

Output the PRD as clean markdown directly in the conversation, then write it to the appropriate file. Use the section structure from `./prd-template.md`.
