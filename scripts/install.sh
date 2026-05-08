#!/usr/bin/env bash
# Installs shell aliases for claude-plugins scripts.
# Safe to run multiple times — skips aliases that already exist.

set -euo pipefail

MARKETPLACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHELL_RC="${HOME}/.zshrc"

add_alias() {
  local name="$1"
  local target="$2"
  if grep -q "alias ${name}=" "${SHELL_RC}" 2>/dev/null; then
    echo "  [skip] ${name} already in ${SHELL_RC}"
  else
    echo "alias ${name}=\"bash ${target}\"" >> "${SHELL_RC}"
    echo "  [added] ${name} → ${target}"
  fi
}

echo "Installing claude-plugins aliases into ${SHELL_RC}..."

# ralph — AFK implementation loop
add_alias "ralph" "${MARKETPLACE_DIR}/dev/scripts/ralph/ralph.sh"

echo "Done. Restart your shell or run: source ${SHELL_RC}"
