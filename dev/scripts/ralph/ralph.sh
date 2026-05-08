#!/usr/bin/env bash
# Ralph — AFK implementation loop.
# Usage: ralph.sh [--agent claude|opencode] [--branch <name>] [--issues <file>] [--iterations <n>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="${SCRIPT_DIR}/$(basename "${BASH_SOURCE[0]}")"
PROMPT_TEMPLATE="${SCRIPT_DIR}/prompt.md"

# ── Internal window mode ──────────────────────────────────────────────────────
# Invoked by the orchestrator as: ralph.sh --_run-window <iter> --agent <agent>
if [[ "${1:-}" == "--_run-window" ]]; then
  ITER="$2"; shift 2
  AGENT="claude"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --agent) AGENT="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  PROMPT_FILE="/tmp/ralph_prompt_${ITER}.txt"
  OUTPUT_FILE="/tmp/ralph_output_${ITER}.txt"
  FLAG_FILE="/tmp/ralph_done_${ITER}"

  echo "[ralph] iter ${ITER} | agent: ${AGENT}"
  echo "[ralph] Streaming agent output..."
  echo ""

  case "${AGENT}" in
    claude)
      cat "${PROMPT_FILE}" | claude --dangerously-skip-permissions --print | tee "${OUTPUT_FILE}"
      ;;
    opencode)
      OPENCODE_CONFIG_CONTENT='{"permission":"allow"}' opencode --print < "${PROMPT_FILE}" | tee "${OUTPUT_FILE}"
      ;;
    *)
      echo "Unknown agent: ${AGENT}" >&2
      echo "ERROR" > "${FLAG_FILE}"
      exit 1
      ;;
  esac

  echo ""
  if grep -q '<promise>NO MORE TASKS</promise>' "${OUTPUT_FILE}" 2>/dev/null; then
    echo "NO_MORE_TASKS" > "${FLAG_FILE}"
  else
    echo "DONE" > "${FLAG_FILE}"
  fi

  echo "─── Ralph: iter ${ITER} complete. Press Enter to close. ───"
  read -r _
  exit 0
fi

# ── Bootstrap tmux ────────────────────────────────────────────────────────────
if [[ -z "${TMUX:-}" ]]; then
  exec tmux new-session -As ralph "${SCRIPT_PATH}" "$@"
fi

# ── Defaults ──────────────────────────────────────────────────────────────────
AGENT="claude"
BRANCH=""
ISSUES_FILE=""
MAX_ITERATIONS=0
ITERATION=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent)      AGENT="$2";          shift 2 ;;
    --branch)     BRANCH="$2";         shift 2 ;;
    --issues)     ISSUES_FILE="$2";    shift 2 ;;
    --iterations) MAX_ITERATIONS="$2"; shift 2 ;;
    *) echo "Unknown flag: $1" >&2; exit 1 ;;
  esac
done

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

# ── Main loop ─────────────────────────────────────────────────────────────────
while true; do
  ITERATION=$((ITERATION + 1))

  if [[ "${MAX_ITERATIONS}" -gt 0 ]] && [[ "${ITERATION}" -gt "${MAX_ITERATIONS}" ]]; then
    echo "[ralph] Reached max iterations (${MAX_ITERATIONS}). Stopping."
    break
  fi

  echo ""
  echo "━━━ Ralph: iteration ${ITERATION} ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  echo "[ralph] Fetching issues..."
  ISSUES=$(fetch_issues)

  echo "[ralph] Reading recent commits..."
  RECENT_COMMITS=$(git log --oneline -5 2>/dev/null || echo "(no commits yet)")

  echo "[ralph] Detecting test commands..."
  eval "$(bash "${SCRIPT_DIR}/../detect-test-cmd.sh")"

  echo "[ralph] Building prompt..."
  PROMPT_FILE="/tmp/ralph_prompt_${ITERATION}.txt"
  FLAG_FILE="/tmp/ralph_done_${ITERATION}"
  rm -f "${FLAG_FILE}"

  RALPH_ISSUES="${ISSUES}" RALPH_COMMITS="${RECENT_COMMITS}" \
    RALPH_TEST="${TEST_CMD:-}" RALPH_TYPECHECK="${TYPECHECK_CMD:-}" \
    python3 -c "
import os, pathlib
t = pathlib.Path('${PROMPT_TEMPLATE}').read_text()
t = t.replace('{{ISSUES}}', os.environ['RALPH_ISSUES'])
t = t.replace('{{RECENT_COMMITS}}', os.environ['RALPH_COMMITS'])
t = t.replace('{{TEST_CMD}}', os.environ['RALPH_TEST'])
t = t.replace('{{TYPECHECK_CMD}}', os.environ['RALPH_TYPECHECK'])
print(t, end='')
" > "${PROMPT_FILE}"

  WINDOW_NAME="ralph-iter-${ITERATION}"
  echo "[ralph] Spawning tmux window '${WINDOW_NAME}'..."
  WINDOW_INDEX=$(tmux new-window -P -F '#{window_index}' -n "${WINDOW_NAME}" \
    "bash '${SCRIPT_PATH}' --_run-window ${ITERATION} --agent ${AGENT}; exec bash")

  echo "[ralph] Waiting for iter ${ITERATION} to complete (window ${WINDOW_INDEX})..."

  while true; do
    if [[ -f "${FLAG_FILE}" ]]; then
      break
    fi
    if ! tmux list-windows -F '#{window_index}' 2>/dev/null | grep -q "^${WINDOW_INDEX}$"; then
      echo "[ralph] Window closed before completing. Stopping."
      exit 1
    fi
    sleep 2
  done

  RESULT=$(cat "${FLAG_FILE}")

  if [[ "${RESULT}" == "NO_MORE_TASKS" ]]; then
    echo "[ralph] No more tasks. Exiting."
    break
  fi

  echo "[ralph] Pushing..."
  git push 2>/dev/null || true
done

echo "[ralph] Done."
