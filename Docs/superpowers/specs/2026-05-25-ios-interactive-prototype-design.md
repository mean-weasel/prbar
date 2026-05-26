# PRBar iOS Interactive Prototype Design

## Purpose

Evolve the static iOS HTML mockups into a complete interactive mobile HTML prototype. The prototype should feel like a small app rather than a board of screens, so the product loop can be tested before native SwiftUI implementation.

The prototype remains a UX artifact. It should use realistic fixture data, not real GitHub authentication or API calls.

## Product Loop

The prototype should validate this loop:

1. Check merged PRs in PRs.
2. Inspect PRs for totals, repo distribution, and recent PRs.
3. Browse date-grouped shipping moments from included repositories.
4. Adjust included repositories through More > Repos.
5. Create a share card from either PRs or a GitHub Release.
6. Adjust card theme and privacy.
7. Preview the final proof-of-work card.

## App Structure

The interactive version should replace the current static screen board with a single phone-sized app shell.

Primary bottom navigation:

- PRs
- Releases
- Share
- More

More menu:

- Repos
- Settings
- Privacy
- Sample Data
- About

Repos should live under More rather than in the primary nav. It is important, but it is a configuration surface, not a daily destination.

## Screens

### PRs

PRs remains the default screen.

Behavior:

- Day / Week / Month range selector updates the headline metric, chart, repo mix, and recent PR list.
- Make Card starts a card from the currently selected PRs range.
- A high-PRs moment can appear when the selected range has enough PRs.
- Includes Summary, Repos, and Distribution views inside the tab.
- Tapping a repo opens that repo's PR list for the selected range.
- Reflects the currently included repositories.

### Releases

Releases should be a shipping-moments timeline based on actual GitHub Releases first, with tagged versions as a fallback when a repo tags versions without publishing GitHub Release notes.

Behavior:

- Shows shipping moments only from included repositories.
- Groups moments by date, starting with recent weeks and earlier months.
- Each row includes repo, tag or version, source badge, date, title, and notes preview.
- Source badges distinguish GitHub Release from Tag.
- Selecting a GitHub Release shows original release notes and actions.
- Selecting a Tag shows a generated summary from related merged PRs and clearly labels it as generated.
- Share Release/Tag opens Share with shipping-moment metadata preloaded.
- Open on GitHub can be a non-network prototype action that displays or copies the release or tag URL.
- Copy notes can copy fixture notes or show a copied state.

The screen should not imply generated tag summaries are official release notes. Future annotation can be hinted at as a later capability, but not treated as core v1 behavior.

### Share

Share is the proof-of-work studio.

Behavior:

- Can start from current PR range or selected release.
- Theme picker changes the preview.
- Privacy toggles affect repo names, handle visibility, exact counts, and private repo labels.
- Share Preview shows the final card artifact in a dedicated preview state.

Initial card sources:

- PRs range
- GitHub Release

Initial themes:

- Clean
- Terminal
- Launch
- Hype
- Minimal

### More

More is a native-feeling menu for secondary app surfaces.

Behavior:

- Tapping a More item opens that screen within the same phone shell.
- Back or close returns to More.

### Repos

Repos controls the data boundary for PRs, Releases, and Share.

Behavior:

- Search filters repositories.
- Include/exclude toggles update the app state.
- Included repositories affect PRs, Releases, and Share.
- Include all restores all repositories.
- Private repositories are clearly labeled.

### Settings

Settings remains simple.

Behavior:

- Shows GitHub connection status.
- Shows default range.
- Shows refresh behavior.
- Shows card privacy defaults.

### Privacy

Privacy makes share-card defaults explicit.

Behavior:

- Toggle repo names.
- Toggle exact counts.
- Toggle GitHub handle.
- Toggle private repo labels.

### Sample Data

Sample Data explains that the prototype is fixture-backed.

Behavior:

- Shows a short list of included fixture entities: repos, PRs, releases, and share.
- Provides reset demo data action.

### About

About gives context without becoming a marketing page.

Behavior:

- Short product description.
- Notes that this is an interactive prototype.

## Data Model

Use in-file fixture data or a small local data module. No network calls.

Core fixture entities:

- repositories
- merged pull requests
- GitHub releases
- share card drafts
- app settings

Repository fields:

- id
- name
- visibility
- color
- included

Pull request fields:

- id
- title
- repoId
- mergedAt
- number

Release fields:

- id
- repoId
- title
- tag
- date
- notes
- url

Card draft fields:

- sourceType
- sourceId
- range
- theme
- privacy settings

## Auth And GitHub Integration Decisions

- Model auth as a state machine: signed out, permission rationale, connecting, repo setup, privacy setup, syncing, authenticated, and recoverable issue.
- Prefer GitHub App OAuth with least-privilege access and explicit private-repo opt-in.
- Store tokens in Keychain in the native app.
- Cache derived stats separately from raw private repo text where possible.
- Treat private repo names, PR titles, release notes, exact counts, org names, and links as share-sensitive.
- Key repositories by durable GitHub IDs in production, not owner/name.
- Show last sync, stale cache, partial sync, rate limit, SSO, and reconnect states.

## Implementation Direction

Use plain HTML, CSS, and vanilla JavaScript. Do not introduce React, Vite, or another frontend framework for this prototype.

Preferred file shape:

- `mockups/ios/index.html`: app shell and semantic screen containers
- `mockups/ios/styles.css`: mobile app layout, navigation, screens, share, and responsive wrapper
- `mockups/ios/app.js`: fixture data, app state, render functions, and event handlers
- `scripts/verify-ios-mockups.mjs`: update required checks for interactive prototype screens and copy

Keep the current static mockup visual language, but replace the board-like experience with a single interactive phone app. A small desktop wrapper can remain around the phone to make review pleasant in Chrome.

## Verification

Required checks:

- `npm run verify:ios-mockups`
- JavaScript syntax check
- Desktop browser screenshot
- Mobile browser screenshot

Manual interaction checks:

- bottom navigation changes screens
- More menu opens Repos, Settings, Privacy, Sample Data, and About
- Day / Week / Month changes PRs
- repo inclusion changes Releases
- selecting a release updates release details
- Make Release Card opens a release card draft
- theme changes update card preview
- privacy toggles update card preview

## Out Of Scope

- native iOS implementation
- real GitHub OAuth
- real GitHub API calls
- backend storage
- public profiles
- social graph
- AI-generated release summaries
- real native share sheet

## Approval Gate

This prototype should be reviewed in Chrome before any native iOS implementation begins.
