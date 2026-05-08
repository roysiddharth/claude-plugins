---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
---

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time.

If a question can be answered by exploring the codebase, explore the codebase instead.

## Process

1. **Understand the scope** — Before asking anything, read the user's plan or description carefully. If it's vague, ask one clarifying question to get enough to proceed.

2. **Map the decision tree** — Identify all major decisions, unknowns, and assumptions. Group them by dependency order: foundational decisions first, derived decisions after.

3. **Grill one branch at a time** — For each open question:
   - State the question clearly and concisely
   - Give your recommended answer with brief reasoning
   - Ask the user to confirm, override, or elaborate
   - Only proceed to the next question once this one is resolved

4. **Surface hidden assumptions** — If the user's answer implies a downstream assumption, name it explicitly before moving on.

5. **Resolve the full tree** — Continue until every branch of the decision tree is resolved and both you and the user have a shared, unambiguous understanding of the plan.

6. **Summarize** — Once all decisions are resolved, output a concise decision log: each question, the chosen answer, and any key rationale.

## Tone

- Direct and rigorous — no softening
- Provide a concrete recommendation for every question, don't just ask open-endedly
- Push back if an answer is vague or contradicts a prior decision
- Act like a senior engineer who has shipped this before and knows where plans fall apart
