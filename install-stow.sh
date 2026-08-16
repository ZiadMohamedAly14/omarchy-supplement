#!/bin/bash
# GNU Stow — not part of the Omarchy 4 base package set.
set -euo pipefail

if command -v stow &>/dev/null; then
  echo "stow already installed"
  exit 0
fi

omarchy-pkg-add stow
