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

## Current iOS Growth UX

The app reads live PostHog configuration from runtime environment values first,
then from these build-time `Info.plist` keys embedded by the iOS workflows:

- `PRBarPostHogHost`
- `PRBarPostHogProjectID`
- `PRBarPostHogPersonalAPIKey`
- `PRBarPostHogDashboardID`

On launch, Growth restores the last successful live Growth snapshot from the
local cache before the first render only when the cached PostHog host, project
ID, and dashboard ID match the app's current configuration. If that restored
snapshot is already marked `Live PostHog`, the first-appearance auto-refresh is
skipped so relaunches stay fast and do not immediately replace live cached data
with fallback data. The toolbar refresh button and pull-to-refresh always
request a fresh PostHog snapshot.

The configured Bleep dashboard currently maps PostHog tiles into Growth like
this:

- `Weekly Visitors` -> `Weekly visitors`, augmented with a daily `$pageview`
  distinct-person series for the selected range when the daily query succeeds.
- `Daily Pageviews` -> `Daily pageviews`, augmented with a daily `$pageview`
  count series for the selected range when the daily query succeeds.
- `Traffic Sources` -> the PostHog source list.
- `Top Pages` -> the PostHog top pages list.

Daily series augmentation is best-effort. If the separate HogQL daily-series
query fails after the dashboard tiles load, Growth keeps the dashboard-backed
snapshot, surfaces a `PostHog daily series unavailable` issue in the snapshot,
and renders the selected date window from the available dashboard tile data.
The physical-device preflight currently probes dashboard metadata and
`run_insights`; it does not yet preflight this separate daily-series query.

Dashboard selection is still configuration-driven. The iOS app shows the
configured dashboard and connection diagnostics, but does not yet let users edit
the PostHog project, API key, or dashboard selection in-app.
