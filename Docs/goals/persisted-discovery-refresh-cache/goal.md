# Persisted Discovery Refresh Cache

## Original Request

Use GoalBuddy goal prep to create measurable acceptance criteria for a second refresh optimization round after the persisted merged-PR incremental cache work.

## Interpreted Outcome

PR Menu Bar refresh after app/provider restart should avoid foreground GitHub discovery requests when a safe persisted discovery snapshot exists, so a compatible restarted refresh can approach the current warm in-memory path: one foreground incremental GraphQL PR request.

## Goal Kind

Specific implementation tranche.

## Oracle

The goal is complete only when deterministic tests and the refresh benchmark prove a compatible persisted discovery + persisted PR-cache restart path avoids foreground discovery requests and still falls back safely for stale, corrupt, token-mismatched, or incompatible discovery state.

## Measurable Acceptance Criteria

- Fixture benchmark includes a `persisted_discovery_cache_refresh` or equivalent scenario.
- That scenario proves restarted refresh uses incremental GraphQL mode and avoids `/user/repos`, `/user`, and `/user/orgs` in the foreground request path when persisted discovery is compatible.
- Target request count for the compatible persisted-discovery restart scenario is `1` foreground GitHub request, or a documented lower-bound alternative if Scout finds unavoidable foreground validation.
- Existing persisted PR-cache benchmark behavior remains intact.
- Tests cover token scoping, corrupt-payload fallback, stale-cache fallback, repository/user/org compatibility fallback, and merged-PR cache compatibility with persisted discovery.
- Final verification includes format/file-size checks, targeted tests, refresh benchmark output, full test suite, and a best-effort live timing smoke or explicit skip reason.

## Non-Goals

- Do not optimize release refresh in this tranche unless Scout proves it is inseparable from discovery caching.
- Do not require live GitHub credentials for completion.
- Do not store raw GitHub tokens in cache keys or payloads.
- Do not hide correctness behind stale repository membership; unsafe or ambiguous cache state must fall back to live discovery.

## Likely Misfire

The implementation could persist discovery data but still perform all discovery requests synchronously during manual refresh, making the benchmark look correct for PR range size while the click still feels slow. The board must keep pressure on foreground request count and restarted-refresh behavior.

## Blind Spots To Audit

- Whether current discovery cache stores enough ETag or timestamp information to revalidate cheaply after using persisted state.
- Whether repository filters/settings affect which repositories are safe to reuse.
- Whether org membership or repository permissions changes should invalidate only discovery or also merged-PR cache.
- Whether background revalidation is possible without introducing racey UI state or surprising refresh errors.
- Whether fixture request-count metrics distinguish foreground refresh work from optional background validation work.

## Starter Command

```text
/goal Follow Docs/goals/persisted-discovery-refresh-cache/goal.md.
```
