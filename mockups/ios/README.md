# PRBar iOS Mockups

Interactive HTML prototype for the approved PRBar iOS app direction.

Open `mockups/ios/index.html` in a browser to review:

- Bottom navigation for PRs / Releases / Share / More
- First-run GitHub sign-in and demo mode
- Permission rationale before OAuth
- Repo setup with public/private visibility and SSO-blocked examples
- Privacy defaults before sharing
- Sync and recovery states for connecting, stale data, reconnect, rate limits, no repos, no PRs, and no releases
- More menu with Repos, Settings, Privacy, Sample Data, and About
- PRs summary in Day / Week / Month ranges with tappable calendar days
- PRs detail from included repos, with repo drill-down and distribution views
- Shipping moments from included repos: GitHub Releases plus tagged versions, organized by calendar day
- Releases Day / Week / Month views with a weekly strip and compact monthly heat map
- Repository inclusion controls
- Work-card composer from PR or release sources
- Public/evidence card sides, with release evidence aggregated on the evidence side
- Export sheet choices for public-side image, saved image, copied image, captions, and optional evidence-side exports
- Clean, Terminal, Launch, Hype, and Minimal share-card themes
- Style & Privacy sheet for controls that update the preview

This prototype is fixture-backed and does not call GitHub. Native iOS implementation should wait until this package is reviewed.

Review links can open specific states with query parameters, for example `?tab=share`, `?tab=share&side=back`, or `?tab=share&sheet=share`.

## Prototype State Links

| State | Link |
| --- | --- |
| Welcome | `?auth=signed-out` |
| Permission rationale | `?auth=permissions` |
| Connecting | `?auth=connecting` |
| Repo setup | `?auth=repo-setup` |
| Privacy defaults | `?auth=privacy` |
| Initial sync | `?auth=syncing` |
| Expired token | `?auth=expired` |
| Rate limit | `?auth=rate-limit` |
| No repositories | `?empty=no-repos` |
| No activity | `?empty=no-activity` |
| No releases | `?empty=no-releases` |
| Private share warning | `?tab=share&private-warning=true` |
| PR distribution | `?tab=prs` |
| PR repo detail | `?tab=prs&repo=prbar` |
| Releases calendar | `?tab=releases` |
| Release detail | `?tab=releases&release=tag-launch-100` |

## Native Mapping

The reviewed HTML surfaces map to the SwiftUI implementation plan in
`Docs/superpowers/plans/2026-05-26-ios-swiftui-implementation.md`.
