# PRBar iOS App Design

## Purpose

PRBar iOS extends the macOS menu bar app into a mobile companion for checking pull request activity on the road and turning GitHub Releases into polished proof-of-work cards.

The first iOS direction is a hybrid product:

- a private, glanceable dashboard for personal PR and release activity
- a share-card studio for public proof of work based on GitHub Releases

The social layer starts with exportable visual artifacts rather than a feed, public profile, or social graph.

## Product Positioning

PRBar iOS should feel like a compact shipping fitness tracker for builders. It helps users understand their shipping rhythm privately, then selectively share credible evidence of work.

The product should emphasize:

- shipped work
- rhythm
- momentum
- distribution
- proof of work

The product should avoid framing users through blunt productivity scoring or leaderboard language.

Preferred language:

- "Shipping rhythm"
- "Work landed"
- "Merged this month"
- "Momentum"
- "Repo mix"
- "Best stretch"
- "Share proof of work"

Avoid or use carefully:

- "Productivity score"
- "Grind"
- "Rank"
- "Top performer"

## Core User Loop

1. Open PRBar on iPhone.
2. See current pull request activity in under five seconds.
3. Tap into detail if needed.
4. Select a GitHub Release or notable shipping moment worth sharing.
5. Generate a polished card from release notes and activity metadata.
6. Save or share the card.

The app should remain useful even if the user never shares anything.

## Information Architecture

The first concept uses six main areas:

- Today
- Activity
- Releases
- Cards
- Repos
- Settings

There should not be a dedicated Social tab in the first design. Social behavior lives in Cards and release artifacts. Later versions can evolve Cards into public profiles, card galleries, messaging, or discovery.

## Range Model

The app uses three primary time ranges:

- Day
- Week
- Month

Week is the default home range. Day supports quick on-the-road check-ins. Month is the default professional share-card range.

Charts adapt by range:

- Day: chronological activity and, when useful, PRs by hour
- Week: PRs by day
- Month: PRs by day or week depending on density

## Screens

### Today

Today is the app's front door. It should be glanceable, native, and emotionally satisfying.

Core elements:

- GitHub handle and account status
- Day / Week / Month segmented control
- headline metric, such as "28 merged"
- momentum versus previous period
- compact distribution chart
- repo mix preview
- recent merged PRs
- contextual Make Card action

The Make Card action can become more prominent when the app detects a standout moment, such as a high-volume period, new personal best, broad repo distribution, or release-like burst.

### Activity

Activity provides deeper inspection without becoming a heavy analytics dashboard.

Core elements:

- larger chart
- range selector
- repo filter
- repo breakdown
- recent merged PR list
- comparison to previous period
- moments such as best stretch or highest-output day

Useful subviews:

- Timeline
- Repos
- PRs
- Moments

### Releases

Releases is the bridge from private GitHub activity to public proof of work. The first version should import actual GitHub Releases from the user's selected repositories, then help the user choose which release to turn into a polished card.

Core elements:

- repository selector for which repos are included
- imported GitHub Releases from selected repositories
- release title, tag, date, repo, and original release notes
- privacy controls for repo names, exact dates, and private details
- included PR or commit references when available from GitHub metadata
- Make Release Card action
- Copy release notes action

The first mockup should keep Releases curated and static, but its mental model should be GitHub Releases first rather than AI-written recaps first. Later versions can allow users to annotate releases with context, lessons, launch notes, links, screenshots, or AI-assisted summaries in addition to the original release notes.

### Repos

Repos controls the data boundary for the app. It should mirror the macOS menu bar app's include/exclude mental model so users understand exactly which repositories contribute to Activity, Releases, and Cards.

Core elements:

- discovered GitHub repositories
- search
- include/exclude toggles
- private repository indicators
- repo color dots
- Include all action
- clear note that selected repos power stats, releases, and share cards

### Cards

Cards is the social primitive.

It has two modes:

- Create: start from a stat, period, or moment
- Gallery: view, reshare, or recreate saved cards

Composer controls:

- theme
- range
- metric focus
- repo visibility
- handle visibility
- exact or rounded count
- caption style

Export actions:

- native share sheet
- save image
- copy image

Future actions can include publishing to a PRBar profile.

### Settings

Settings stays utilitarian.

Core elements:

- GitHub connection
- tracked repositories
- release repository selection
- default date range
- refresh behavior
- card privacy defaults
- theme defaults
- about PRBar

Default card privacy is important. Users should be able to share output without exposing private repository names, client work, or exact counts.

## Share Card Themes

The app shell should be restrained and professional. Share cards can carry more personality.

Initial themes:

- Clean: professional default for LinkedIn, GitHub, and founder updates
- Terminal: dark, technical, monospaced accents
- Launch: polished, editorial, useful for release weeks
- Hype: expressive and playful, for high-energy sharing
- Minimal: graph, count, range, handle, and small PRBar mark

## Share Card Anatomy

A card can include:

- GitHub handle
- range label
- headline metric
- distribution chart
- repo mix or top repo
- momentum or moment label
- optional caption
- small PRBar mark

Example copy:

- Clean: "42 merged PRs this month"
- Terminal: "git merged --count 42 --range month"
- Launch: "A month of shipped work"
- Hype: "Big merge month"
- Minimal: "42 merged / May 2026"

## Mockup Plan

The first design deliverable should be an HTML mockup package before any native iOS implementation.

The HTML prototype should be static, responsive, and screenshot-friendly. It should model the intended iPhone experience closely enough to test layout, density, chart treatment, and share-card composition.

Recommended mockup files:

- an iPhone app shell showing Today, Activity, Releases, Cards, Repos, and Settings
- share card previews for Clean, Terminal, and Hype themes
- first-run and sample-data states
- refresh, empty, and privacy-hidden states

The HTML mockups should answer:

1. Does the home screen communicate useful status in under five seconds?
2. Does the card composer feel fun without becoming gimmicky?
3. Do shared cards feel like credible proof of work rather than vanity spam?

## Specific Mockup Screens

The first HTML mockup set should include:

1. Today, Week default
2. Today, Day view
3. Today, Month view
4. Activity detail
5. Releases
6. Repo filter sheet
7. Repo selection
8. Card entry point
9. Card composer
10. Card preview, Clean theme
11. Card preview, Terminal theme
12. Card preview, Hype theme
13. Cards gallery
14. Settings and auth

The first native implementation should wait until this mockup set has been reviewed.

## States To Mock

The mockups should include:

- sample data mode
- connected GitHub mode
- refreshing
- refresh failed while previous data remains visible
- no PRs in selected range
- private repo names hidden
- high-activity moment detected
- first-run connect GitHub screen

## Data Model Fit

The existing macOS app already has useful domain concepts:

- activity windows
- bucketed activity
- repositories
- refresh state
- sample versus GitHub data source
- GitHub merged pull requests

The iOS design should reuse this mental model, but not copy the macOS popover directly. The relationship should be:

- macOS: passive ambient signal while working
- iOS: mobile check-in and share-card creation
- future web/profile: public artifacts and discovery

## Future Opportunities

After the dashboard and card loop works, the product can expand toward:

- public PRBar profiles
- card galleries
- release cards from GitHub Releases
- AI-written work summaries
- messaging opportunities around high-velocity work
- public launch posts based on GitHub Releases
- team or collaborator views

These are intentionally out of scope for the first mockup pass.

## Approval Gate

Before native iOS implementation, review and approve:

- the HTML mockup package
- the core Today flow
- the GitHub Releases import and selection flow
- the Card composer flow
- at least three card themes
- privacy defaults for shared cards
