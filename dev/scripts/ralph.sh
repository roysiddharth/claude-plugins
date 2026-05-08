#!/usr/bin/env bash
# Ralph — AFK implementation loop.
# Usage: ralph.sh [--agent claude|opencode] [--branch <name>] [--issues <file>] [--iterations <n>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PROMPT_FILE="${CLAUDE_PLUGIN_ROOT:-${PLUGIN_ROOT}}/skills/ralph/prompt.md"

# Defaults
AGENT="claude"
BRANCH=""
ISSUES_FILE=""
MAX_ITERATIONS=0  # 0 = unlimited
ITERATION=0

# Parse flags
while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)    AGENT="$2";      shift 2 ;;
    --branch)   BRANCH="$2";    shift 2 ;;
    --issues)   ISSUES_FILE="$2"; shift 2 ;;
    --iterations) MAX_ITERATIONS="$2"; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

# Checkout branch if specified
if [[ -n "${BRANCH}" ]]; then
  git checkout -b "${BRANCH}"
fi

fetch_issues() {
  if [[ -n "${ISSUES_FILE}" ]]; then
    cat "${ISSUES_FILE}"
  else
    gh issue list --label afk --state open --json number,title,body \
      --jq '.[] | "## Issue #\(.number): \(.title)\n\n\(.body)\n---"'
  fi
}

run_agent() {
  local prompt="$1"
  case "${AGENT}" in
    claude)
      echo "${prompt}" | claude --dangerously-skip-permissions --print
      ;;
    opencode)
      OPENCODE_CONFIG_CONTENT='{"permission":"allow"}' opencode --print <<< "${prompt}"
      ;;
    *)
      echo "Unknown agent: ${AGENT}" >&2
      exit 1
      ;;
  esac
}

# Main loop
while true; do
  ITERATION=$((ITERATION + 1))

  if [[ "${MAX_ITERATIONS}" -gt 0 ]] && [[ "${ITERATION}" -gt "${MAX_ITERATIONS}" ]]; then
    echo "Reached max iterations (${MAX_ITERATIONS}). Stopping."
    break
  fi

  # Gather context
  ISSUES=$(fetch_issues)
  RECENT_COMMITS=$(git log --oneline -5 2>/dev/null || echo "(no commits yet)")
  eval "$(bash "${SCRIPT_DIR}/detect-test-cmd.sh")"

  # Build prompt from template
  PROMPT=$(sed \
    -e "s|{{ISSUES}}|${ISSUES}|g" \
    -e "s|{{RECENT_COMMITS}}|${RECENT_COMMITS}|g" \
    -e "s|{{TEST_CMD}}|${TEST_CMD:-}|g" \
    -e "s|{{TYPECHECK_CMD}}|${TYPECHECK_CMD:-}|g" \
    "${PROMPT_FILE}")

  # Run agent
  RESPONSE=$(run_agent "${PROMPT}")
  echo "${RESPONSE}"

  # Check for NO MORE TASKS signal
  if echo "${RESPONSE}" | grep -q '<promise>NO MORE TASKS</promise>'; then
    echo "Ralph: no more tasks. Exiting."
    break
  fi

  # Push after each completed task
  git push 2>/dev/null || true
done
