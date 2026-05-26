# T003 GitHub API Research

## Result

Done.

## Sources

- GitHub REST Search docs source: `https://github.com/github/docs/blob/main/content/rest/search/search.md`
- GitHub issue/PR search qualifiers: `https://docs.github.com/en/search-github/searching-on-github/searching-issues-and-pull-requests`
- GitHub REST Pull Requests: `https://docs.github.com/en/rest/pulls/pulls?apiVersion=2022-11-28`
- GitHub REST Releases: `https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28`
- GitHub REST Repository Tags: `https://docs.github.com/en/rest/repos/repos?apiVersion=2022-11-28#list-repository-tags`
- GitHub REST rate limits: `https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api`
- GitHub REST rate-limit endpoint categories: `https://docs.github.com/en/rest/rate-limit/rate-limit?apiVersion=2022-11-28`

## Merged PR Options

### Option A: REST Search `/search/issues`

Search can express the exact product question:

- `repo:OWNER/REPO is:pr is:merged merged:>=YYYY-MM-DD`
- optional `author:USERNAME` if the product later wants only the signed-in user's authored PRs.
- `sort=updated` or default relevance; date filtering comes from search qualifiers.

Pros:

- Directly supports `merged` date qualifier and `is:merged`.
- Can return issue-style PR results with `number`, `title`, `html_url`, `closed_at`, and `repository_url`.
- Good for a first date-bounded PR activity slice across a small selected repo set.

Cons:

- Search has a custom rate limit: authenticated search requests are capped at 30 requests/minute, while unauthenticated search is 10 requests/minute.
- Search results are capped at 1,000 results per query.
- Query length is limited to 256 characters excluding operators/qualifiers, so combining many selected repos in one query is not robust.
- Search can return partial/incomplete results when a query times out.
- Multi-resource searches silently omit inaccessible repos rather than listing every omitted repo.

### Option B: REST Pull Requests `/repos/{owner}/{repo}/pulls`

The pull request endpoint lists PRs by repository and supports:

- `state=closed`
- `sort=updated`
- `direction=desc`
- `per_page` up to 100 and `page`.

Pros:

- Uses the normal REST core rate bucket instead of the search bucket.
- Per-repository paging fits the selected-repo model and avoids query length issues.
- Uses the same owner/repo path pattern as releases/tags and the existing repository client.
- More predictable for deterministic fixtures and partial per-repo failure handling.

Cons:

- The list endpoint does not filter by `merged_at` server-side.
- It returns closed but unmerged PRs too; the client must filter payloads with non-null `merged_at`.
- Date-window cutoff must be enforced client-side and may need a page cap to avoid scanning old history forever.

## Release and Tag Options

### GitHub Releases

`GET /repos/{owner}/{repo}/releases` lists releases. The endpoint requires "Contents" read permission for fine-grained tokens and can be used without auth for public repos. Response payloads include `tag_name`, `name`, `body`, `html_url`, `created_at`, and `published_at`.

This maps cleanly to `ReleaseMoment(source: .release)`.

### Tags

`GET /repos/{owner}/{repo}/tags` lists tags and returns tag names plus a commit object with a `url`. It does not provide release notes and does not directly include a semantic published date in the list response.

This maps less cleanly:

- First slice can include tags as `ReleaseMoment(source: .tag)` using the tag list and the commit URL as a follow-up date source only if we also fetch the commit.
- If we do not fetch commits, tags can be present but date ordering would be weak.
- Better first slice: fetch Releases first and design tag fallback explicitly. If tags are required in the first slice, add commit-fetch mapping tests.

## Permissions and Scopes

- Current iOS OAuth config uses `public_repo`.
- Public repo PRs/releases/tags can be read unauthenticated or with public repo scope.
- Private repo activity requires broader private repository access. Classic OAuth would need `repo`; fine-grained/GitHub App models map to repository-specific permissions such as Pull requests read and Contents read.
- Privacy implication: private repo data must remain excluded unless the user intentionally selected private repositories, and share surfaces must keep existing private-data warnings.

## Pagination and Rate Limits

- REST list endpoints use `per_page` max 100 and `page`.
- Current repository client already uses "loop pages until a page returns fewer than 100" and fixture transports; reuse that pattern.
- For PRs, add a page cap or stop when the oldest merged/updated item is older than the requested range.
- Authenticated REST calls normally have a 5,000 requests/hour primary limit.
- Search has a separate, tighter rate limit and is more fragile for many selected repos.
- Secondary rate limits discourage high concurrency; the app should fetch selected repos sequentially or with very low concurrency.
- Rate-limit headers (`x-ratelimit-*`) are available and should be captured eventually, but the first slice can surface a generic recoverable sync issue.

## Recommendation for Judge

Use REST per-repository endpoints for the first implementation slice:

- `GET /repos/{owner}/{repo}/pulls?state=closed&sort=updated&direction=desc&per_page=100&page=N`
- filter `merged_at != nil` and within a bounded date window in the client.
- `GET /repos/{owner}/{repo}/releases?per_page=100&page=N`
- optionally defer tag fallback until a second slice because tags require commit-date enrichment and do not include notes.

Why:

- It reuses the existing session/transport/pagination pattern from PR #44.
- It avoids Search API's custom limit and result cap.
- It keeps selected-repo privacy boundaries explicit.
- It is straightforward to test with deterministic fixture responses.

## Test-Double Implications

- Add a static activity provider for UI tests.
- Add fixture transport responses for PR pages and release pages.
- Unit-test request URLs/headers, payload mapping, pagination, selected-repo filtering, private repo inclusion behavior, and per-repo fetch failure behavior.
- No test should require real GitHub credentials or network access.
