#!/usr/bin/env bash
set -euo pipefail

swift-format lint --recursive --strict Sources Tests
