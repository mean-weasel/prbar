# T003 GitHub Auth And API Research

## Sources

- GitHub OAuth app authorization: https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/authorizing-oauth-apps
- GitHub OAuth scopes: https://docs.github.com/en/apps/oauth-apps/building-oauth-apps/scopes-for-oauth-apps
- GitHub authenticated repositories endpoint: https://docs.github.com/en/rest/repos/repos#list-repositories-for-the-authenticated-user
- GitHub REST rate limits: https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api
- Apple `ASWebAuthenticationSession`: https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession
- Apple Keychain Services: https://developer.apple.com/documentation/Security/keychain-services

## GitHub Auth Options

### ASWebAuthenticationSession + OAuth Web Flow

- Fits iOS best because Apple provides an app-mediated browser auth session and callback URL handling.
- GitHub's web flow redirects the user to GitHub, redirects back to the configured callback URL, and then the app exchanges the code for an access token.
- Requires an OAuth app registration, client ID, callback URL scheme/URL, and a backend or other safe token-exchange strategy if a client secret is required.
- Good long-term UX, but the first local implementation needs a test-double boundary because CI cannot complete real GitHub browser auth.

### Device Flow

- GitHub supports device authorization for apps without direct browser access. The app requests a device code, asks the user to visit GitHub's device URL, then polls for an access token.
- Requires enabling device flow in the OAuth app settings.
- Easier to test with fake polling states and avoids custom callback routing, but it is less native-feeling on iOS than `ASWebAuthenticationSession`.
- Polling must honor GitHub's returned minimum interval and handle pending, slow-down, expired, denied, and success states.

### Personal Access Token / gh CLI

- Already used by the macOS app and documented in `Docs/GitHubIntegration.md`.
- Not a good iOS app UX and should not be the new iOS auth architecture, but its transport/request model is useful for service tests.

## Scope And Permissions

- Listing authenticated repositories can use GitHub App user access tokens or fine-grained personal access tokens with read metadata; public-only listing can work unauthenticated.
- Classic OAuth scopes are coarse. `public_repo` limits access to public repositories, while `repo` grants broad access to public/private repositories and much more. Users can also reduce granted scopes, so the app must inspect granted scopes and degrade gracefully.
- For a privacy-first first slice, prefer public-repo read behavior when possible and treat private repo access as an explicit later opt-in unless the chosen OAuth registration requires a broader scope.

## Repository API Constraints

- Use `GET /user/repos` to list repositories the authenticated user can access through ownership, collaboration, or org membership.
- Query options include `visibility`, `affiliation`, `type`, `sort`, `direction`, `per_page`, and `page`.
- Pagination matters; `per_page` max is 100, so the repository client should keep fetching pages until a short page or no next page.
- The response includes `permissions`, `private`, `full_name`, owner login, URLs, and visibility fields that map well to the iOS `Repository` model.

## User API Constraints

- The app needs `GET /user` or equivalent OAuth identity response to populate `GitHubUser(login:displayName:)`.
- Display name may be absent; login should remain the stable required identifier.

## Rate Limit And Error Constraints

- REST responses include rate-limit headers such as limit, remaining, used, reset, and resource.
- Exceeding primary limits can produce `403` or `429` with zero remaining requests.
- The iOS first slice should capture enough response metadata to show a recoverable issue state later, but it does not need a full rate-limit UI before repo selection is working.

## Keychain Constraints

- Apple positions Keychain Services as secure storage for small secrets and account data.
- Token/session persistence should be behind a protocol so unit tests can use memory storage and the app can use Keychain.
- Store only the minimum session material needed. Avoid placing tokens in `UserDefaults`, logs, test fixtures, screenshots, PR text, or GoalBuddy receipts.

## CI And Test-Double Implications

- CI should not require real GitHub credentials, a real OAuth app secret, or a user browser session.
- Introduce protocols for auth coordination, session storage, and GitHub API fetching.
- Unit tests can verify request construction, session persistence, repository mapping, pagination, error states, and privacy defaults with in-memory fakes.
- UI tests should use launch arguments or app configuration to inject a fake auth service that simulates successful sign-in and fetched repos.

## Open Decisions For Judge

- Whether the first implementation should model the product architecture as `ASWebAuthenticationSession` first with a fake token exchange, or use device flow first because it can be completed without backend infrastructure.
- Whether to add a real OAuth app client ID now or keep the concrete auth coordinator behind configuration until credentials exist.
- Whether to extract shared GitHub request/transport models from `Sources/Models` or implement a small iOS-local subset under `apple/PRBarShared`.
- How much private repo support to expose in the first PR: fetched but default-off, public-only by default, or gated behind scope/permission state.
