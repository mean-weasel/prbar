# T004 Refresh Benchmark

`make refresh-benchmark` passed after updating `Tests/PRMenuBarTests/RefreshBenchmarkTests.swift`.

Benchmark scenarios now cover:

- `cold_refresh`: 4 requests, full GraphQL window from `2026-04-25T18:00:00Z` to `2026-05-02T18:00:00Z`.
- `cache_hit_refresh`: 1 request, incremental GraphQL from `2026-05-02T17:30:00Z` to `2026-05-02T18:05:00Z`.
- `cache_expired_refresh`: 4 requests, conditional discovery with three `not_modified` responses and incremental GraphQL from `2026-05-02T17:30:00Z` to `2026-05-02T18:16:00Z`.
- `persisted_cache_refresh`: 4 requests after provider restart, discovery miss plus incremental GraphQL from persisted cache from `2026-05-02T17:30:00Z` to `2026-05-02T18:05:00Z`.

This proves the benchmark can distinguish cold, in-memory warm, cache-expired warm, and persisted warm refresh behavior.
