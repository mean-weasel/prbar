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
- PRs summary in Day / Week / Month ranges
- PRs detail from included repos, with repo drill-down and distribution views
- Shipping moments from included repos: GitHub Releases plus tagged versions
- Repository inclusion controls
- Share composer from PR or release sources
- Front/back card flip, with release evidence aggregated on the back
- Share sheet choices for front, back, both sides, captions, image saves, and messages
- Clean, Terminal, Launch, Hype, and Minimal share-card themes
- Edit Card sheet for style and privacy controls that update the preview

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
