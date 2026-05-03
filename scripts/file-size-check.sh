#!/usr/bin/env bash
set -euo pipefail

OVERSIZED=$(
  find Sources Tests -name '*.swift' \
    -exec awk 'END { if (NR > 300) print FILENAME ": " NR " lines" }' {} \;
)

if [ -n "$OVERSIZED" ]; then
  echo "Swift files exceeding 300 lines:"
  echo "$OVERSIZED"
  exit 1
fi

