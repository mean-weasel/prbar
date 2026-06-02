# iOS PostHog Dashboard Configuration

The iOS Growth tab can load a PostHog dashboard-backed provider when these
repository settings are present in GitHub Actions:

- `PRBAR_IOS_POSTHOG_HOST` secret
- `PRBAR_IOS_POSTHOG_PROJECT_ID` secret
- `PRBAR_IOS_POSTHOG_PERSONAL_API_KEY` secret
- `PRBAR_IOS_POSTHOG_DASHBOARD_ID` variable

For the initial Bleep KPI dashboard experiment, the dashboard id variable points
at `1362888`. The preview and production install/smoke workflows pass these
values into Xcode so the installed app uses the same dashboard source that the
Growth tab labels in-app.

For this internal prototype, the install workflows embed the PostHog settings in
the app bundle so physical-device installs can read them after launch. Do not
ship a public build with a personal API key in the bundle; move this behind a
backend proxy or a narrower read-only token before broader distribution.
