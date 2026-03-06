#!/usr/bin/env bash
# ensure-playwright-cli.sh — Install playwright-cli if not present
# Exit 0 = ready, Exit 1 = install failed
# Usage: bash .sdd/settings/scripts/ensure-playwright-cli.sh

if command -v playwright-cli >/dev/null; then
  playwright-cli --version
  exit 0
fi

echo "playwright-cli not found. Installing..."
npm install -g @playwright/cli@latest
if [ $? -ne 0 ]; then
  echo "FAILED: npm install @playwright/cli"
  exit 1
fi

playwright-cli install
if [ $? -ne 0 ]; then
  echo "FAILED: playwright-cli install (browser binaries)"
  exit 1
fi

playwright-cli --version
