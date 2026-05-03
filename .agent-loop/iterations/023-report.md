# Iteration 023 Report

## Selected Task
Accept `merged_at` timestamps with and without fractional seconds.

## Changes
- Added fallback ISO8601 decoding for GitHub timestamps without fractional seconds.
- Covered both timestamp variants in merged pull request decoding tests.

## Verification
- `make ci-local` passed.

## Judge
Continue. Timestamp decoding is less brittle; next useful polish is avoiding accidental GitHub provider selection for blank or whitespace-only tokens.
