#!/usr/bin/env bash
# Make sure the `jac` CLI is available, then print its version and the guide list.
# Usage: bash ensure_jac.sh [--with-llm]
#   --with-llm   also install byllm (needed for `by llm` functions and MockLLM tests)
set -euo pipefail

if ! command -v jac >/dev/null 2>&1; then
  echo ">> jac not found; installing..." >&2
  if command -v pip >/dev/null 2>&1 || command -v pip3 >/dev/null 2>&1; then
    PIP=$(command -v pip || command -v pip3)
    "$PIP" install -q jaclang || "$PIP" install -q --user jaclang
  else
    # Official self-contained binary (macOS/Linux; use WSL on Windows)
    curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash
    export PATH="$HOME/.local/bin:$HOME/.jac/bin:$PATH"
  fi
fi

if [[ "${1:-}" == "--with-llm" ]]; then
  python3 -c "import byllm" 2>/dev/null || (pip install -q byllm || pip3 install -q byllm)
fi

command -v jac >/dev/null 2>&1 || { echo "!! jac still not on PATH" >&2; exit 1; }
jac -V 2>&1 | grep -iE "version|jac [0-9]" | head -2 || true
echo
jac guide 2>&1 | grep -E "^  jac-" | sed 's/^  //' || true
