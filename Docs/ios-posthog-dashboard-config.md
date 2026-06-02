# iOS PostHog Dashboard Configuration

The iOS Growth tab can load a PostHog dashboard-backed provider when these
repository settings are present in GitHub Actions:

- `PRBAR_IOS_POSTHOG_HOST` secret
- `PRBAR_IOS_POSTHOG_PROJECT_ID` secret
- `PRBAR_IOS_POSTHOG_PERSONAL_API_KEY` secret
- `PRBAR_IOS_POSTHOG_DASHBOARD_ID` variable

For the initial Bleep KPI dashboard experiment, the dashboard id variable points
at `1362888`, and the project id secret should point at the `bleep-that-sht`
project, `324426`. The personal API key must belong to a PostHog user that can
read that project and must include at least the `dashboard:read`,
`insight:read`, and `query:read` scopes required by the dashboard metadata and
dashboard insight execution APIs.

The preview and production install/smoke workflows pass these values into Xcode
so the installed app uses the same dashboard source that the Growth tab labels
in-app. If a physical Growth smoke renders `Sample fallback` with `PostHog API
key needs attention`, the app received the settings but PostHog returned
`401`/`403`; replace `PRBAR_IOS_POSTHOG_PERSONAL_API_KEY` with an authorized key
for project `324426`.

The production physical smoke workflow runs `scripts/ios-posthog-dashboard-preflight.sh`
before launching the iPhone for live Growth profiles. It probes both the
dashboard metadata endpoint and the `run_insights` endpoint with the configured
secret, so CI can report which PostHog API call is blocked before spending time
on device launch and UI automation.

For this internal prototype, the install workflows embed the PostHog settings in
the app bundle so physical-device installs can read them after launch. Do not
ship a public build with a personal API key in the bundle; move this behind a
backend proxy or a narrower read-only token before broader distribution.
