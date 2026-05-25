# Refresh Efficiency Report

## Scope

This report covers the fixture-backed refresh-efficiency work completed for PR Menu Bar:

- provider-level phase timing and request-count instrumentation
- incremental merged-PR GraphQL search for repeated refreshes
- GitHub REST conditional requests for stable discovery endpoints
- async/await migration decision

Live GitHub credentials were not required. All measurements below are deterministic fixture-backed proof from `build/refresh-benchmark.json` and task receipts.

## Measured Outcomes

| Scenario | T004 baseline request count | Current request count | Current GraphQL mode | Current conditional result | Current provider load |
| --- | ---: | ---: | --- | --- | ---: |
| Cold refresh | 4 | 4 | full, `2026-04-25T18:00:00Z` to `2026-05-02T18:00:00Z` | 3 uncached discovery requests | 3.094 ms |
| Repeated cache-hit refresh | 1 | 1 | incremental, `2026-05-02T18:00:00Z` to `2026-05-02T18:05:00Z` | no discovery requests | 2.983 ms |
| Cache-expired refresh | 4 | 4 | full, `2026-04-25T18:16:00Z` to `2026-05-02T18:16:00Z` | 3 not-modified discovery requests | 2.985 ms |

## Request Counts By Endpoint

| Scenario | `/user/repos` | `/user` | `/user/orgs` | `/graphql` |
| --- | ---: | ---: | ---: | ---: |
| Cold refresh | 1 | 1 | 1 | 1 |
| Repeated cache-hit refresh | 0 | 0 | 0 | 1 |
| Cache-expired refresh | 1 | 1 | 1 | 1 |

## What Improved

Repeated manual refreshes no longer re-query the entire chart window. With a valid merged-PR cache, GraphQL searches start at the previous successful watermark and end at the new refresh time. The benchmark proves the cache-hit refresh searched only `2026-05-02T18:00:00Z` to `2026-05-02T18:05:00Z`.

Discovery refreshes now use ETag validators. When the repository list, authenticated user, and organization list are unchanged, the app reuses cached discovery bodies after 304 responses. The benchmark proves three not-modified hits for `/user/repos`, `/user`, and `/user/orgs`.

Freshness safeguards were added around the incremental path. The app falls back to full merged-PR recompute when there is no cache, discovery changes, the requested display window expands earlier than cached data, or a failed refresh would otherwise advance the watermark.

## Deferred Work

Async/await transport migration is deferred. Refresh already runs off the main thread, and current fixture-backed evidence points to request/range reduction rather than concurrency plumbing. Revisit async/await when live metrics show multi-owner GraphQL fanout, paginated GraphQL searches, or cancellation/backpressure dominates user-visible refresh latency.

## Verification

- `./scripts/format-check.sh`: pass
- `./scripts/file-size-check.sh`: pass
- `make refresh-benchmark`: pass
- `make test`: pass, 77 tests with 0 failures

## Completion Check

The measurable oracle is satisfied for fixture-backed evidence: request counts are reported, GraphQL search ranges are reported, conditional request outcomes are reported, and freshness regressions are covered by tests. Live GitHub timing remains a future validation layer rather than a blocker for this goal.
