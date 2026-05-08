#!/usr/bin/env bash
# Detects test and typecheck commands for the current repo.
# Outputs: TEST_CMD=... and TYPECHECK_CMD=...

set -euo pipefail

TEST_CMD=""
TYPECHECK_CMD=""

# 1. ralph.config.json override
if [[ -f "ralph.config.json" ]]; then
  if command -v jq &>/dev/null; then
    TEST_CMD=$(jq -r '.testCmd // empty' ralph.config.json 2>/dev/null || true)
    TYPECHECK_CMD=$(jq -r '.typecheckCmd // empty' ralph.config.json 2>/dev/null || true)
  fi
  echo "TEST_CMD=${TEST_CMD}"
  echo "TYPECHECK_CMD=${TYPECHECK_CMD}"
  exit 0
fi

# 2. package.json — detect package manager from lockfile
if [[ -f "package.json" ]]; then
  if [[ -f "pnpm-lock.yaml" ]]; then
    PM="pnpm"
  elif [[ -f "yarn.lock" ]]; then
    PM="yarn"
  elif [[ -f "bun.lockb" ]] || [[ -f "bun.lock" ]]; then
    PM="bun"
  else
    PM="npm"
  fi

  # Check if scripts exist in package.json
  if command -v jq &>/dev/null; then
    HAS_TEST=$(jq -r '.scripts.test // empty' package.json 2>/dev/null || true)
    HAS_TYPECHECK=$(jq -r '.scripts.typecheck // empty' package.json 2>/dev/null || true)
  else
    HAS_TEST=$(node -e "const p=require('./package.json'); console.log(p.scripts&&p.scripts.test||'')" 2>/dev/null || true)
    HAS_TYPECHECK=$(node -e "const p=require('./package.json'); console.log(p.scripts&&p.scripts.typecheck||'')" 2>/dev/null || true)
  fi

  [[ -n "${HAS_TEST}" ]] && TEST_CMD="${PM} run test"
  [[ -n "${HAS_TYPECHECK}" ]] && TYPECHECK_CMD="${PM} run typecheck"

  echo "TEST_CMD=${TEST_CMD}"
  echo "TYPECHECK_CMD=${TYPECHECK_CMD}"
  exit 0
fi

# 3. Python — pyproject.toml or setup.py
if [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
  if command -v pytest &>/dev/null; then
    TEST_CMD="pytest"
  fi
  echo "TEST_CMD=${TEST_CMD}"
  echo "TYPECHECK_CMD=${TYPECHECK_CMD}"
  exit 0
fi

# 4. Go
if [[ -f "go.mod" ]]; then
  TEST_CMD="go test ./..."
  echo "TEST_CMD=${TEST_CMD}"
  echo "TYPECHECK_CMD=${TYPECHECK_CMD}"
  exit 0
fi

# 5. Rust
if [[ -f "Cargo.toml" ]]; then
  TEST_CMD="cargo test"
  echo "TEST_CMD=${TEST_CMD}"
  echo "TYPECHECK_CMD=${TYPECHECK_CMD}"
  exit 0
fi

# 6. Makefile with test target
if [[ -f "Makefile" ]] && grep -q "^test:" Makefile 2>/dev/null; then
  TEST_CMD="make test"
  echo "TEST_CMD=${TEST_CMD}"
  echo "TYPECHECK_CMD=${TYPECHECK_CMD}"
  exit 0
fi

# 7. Fallback — empty
echo "TEST_CMD=${TEST_CMD}"
echo "TYPECHECK_CMD=${TYPECHECK_CMD}"
