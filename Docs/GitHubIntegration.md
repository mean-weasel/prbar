# GitHub Integration Plan

The first real GitHub path uses a personal access token supplied outside the repo.
OAuth, device flow, keychain storage, signing, and distribution are intentionally out
of scope until the local product loop proves the provider and refresh behavior.

## Authentication

- Read the token from `PR_MENU_BAR_GITHUB_TOKEN` for local development.
- Treat a missing token as a recoverable configuration state and keep sample data usable.
- Send authenticated requests with `Authorization: Bearer <token>`.
- Keep token persistence out of the app model for now; later UI can choose keychain storage.

## Repository Discovery

- Discover repositories with the REST `/user/repos` endpoint.
- Include repositories where the authenticated user has pull access.
- Use `owner/name` as the stable repository ID.
- Preserve user include/exclude choices by ID when fetched repositories change.
- Default newly discovered repositories to included so first refreshes show useful data.
- Drop removed repositories from the fetched activity list, while keeping settings resilient
  to stale IDs.

## Activity Fetching

- Query merged pull requests per repository for the app's visible history range.
- Bucket merged pull requests by calendar week first, matching the current model.
- Keep API decoding isolated behind `PRActivityProviding` so tests can use fixture JSON.
- Surface provider failures as app state instead of silently replacing real data with samples.

## Rate Limits

- Refresh only on manual action or when `RefreshPolicy` says a scheduled refresh is due.
- Keep daily refresh as the default automatic interval.
- Record response metadata later if rate-limit UI becomes necessary.

## Verification Plan

- Unit-test request construction and payload decoding with fixture transport.
- Unit-test settings reconciliation when repositories are added or removed.
- Unit-test scheduled refresh decisions without waiting for wall-clock time.
- Keep `make ci-local` green after each implementation step.
