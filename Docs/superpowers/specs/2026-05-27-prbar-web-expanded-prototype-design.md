# PRBar Web Expanded Prototype Design

## Goal

Expand the current PRBar web mockup into a connected single-page HTML/CSS/JavaScript prototype that demonstrates the full product shape:

- Public proof and discovery pages for builders, projects, releases, and momentum.
- A signed-in builder command center focused on sharing receipts.
- Founder/operator talent discovery for finding high-velocity builders.
- A clear trust center explaining GitHub access, scoring, privacy, and anti-gaming.

The prototype should remain static and shareable through GitHub Pages at `/web/`. It is a product mockup, not a production web app.

## Positioning

Primary hero line:

> Show the world your receipts.

Supporting message:

> Token usage does not count. Features shipped, PRs merged, releases made, projects launched. PRBar turns your GitHub activity into proof you can share.

Secondary employment message:

> Receipts beat resumes.

The product should be proof-led and GitHub-native. It should push against vague AI-builder claims, token usage flexing, and resume fluff. The value is verified shipped work: PRs, releases, projects, cadence, and source links.

## Prototype Structure

Use one `index.html`, one stylesheet, and one JavaScript file under `mockups/web/`. The experience should behave like a routed app by switching visible views in JavaScript. It should be possible to click through every major page without leaving the static mockup.

Recommended top-level navigation:

- Home
- Proof Network
- Momentum Boards
- Talent
- Dashboard
- Trust

Secondary links and in-page actions should route to:

- Builder Profile
- Release Receipt
- Project Page
- Repo Picker
- Receipt Studio

Do not add a full pricing page in this prototype. Use lightweight calls to action instead:

- Claim your profile
- Scout builders
- Join early access

## Pages

### 1. Home / Product Story

Purpose: explain the product quickly and make the receipt concept memorable.

Content:

- Hero: "Show the world your receipts."
- Token usage contrast: token usage does not count; shipped work does.
- Proof preview cards for PRs, releases, projects, and streaks.
- App family framing: Mac menu bar, iOS app, web profiles.
- CTAs for builders and founders/operators.

### 2. Proof Network

Purpose: a portfolio network backed by GitHub-native activity.

Direction: people and projects first, GitHub proof underneath.

Content:

- Feed of builders and projects with recent verified momentum.
- Feed items that expose source-of-truth details: repo, release tag, PR links, timestamps, contributors, verification state.
- Browsing modes for builders, projects, receipts, repos, and topics.

The page should not feel like a raw commit log or a Product Hunt clone. It should feel like a browsable network of builders and projects where every claim has receipts.

### 3. Builder Profile

Purpose: a career proof profile for builders who want employment, contract, or founding-engineer opportunities.

Direction: employment signal backed by shipped work.

Content:

- Builder headline, stack, AI tools, domains, role targets, and availability.
- Career proof snapshot: PRs, releases, projects, streak, selected repos.
- Featured receipts.
- Recent release and PR history.
- Selected projects.
- Contact/hiring CTA.

Keep social features light. Followers or bookmarks can exist later, but the primary signal is shipped work.

### 4. Release Receipt

Purpose: a factual, shareable page for one release.

Direction: GitHub-native and factual.

Content:

- Release name/version.
- GitHub repo and release tag.
- Published timestamp.
- Verification/source links.
- Imported GitHub release notes.
- Merged PR list with PR number, title, author, merged time, and labels.
- Contributors.
- Diff/commit stats.
- Share receipt URL.

Optional context, such as screenshots, demo links, and builder annotations, should be secondary. Evidence first, story second.

### 5. Project Page

Purpose: show the operating history and shipping momentum of a project.

Direction: proof timeline plus traction-style shipping signal.

Content:

- Project summary, owner/builders, selected repos, live/demo links.
- Proof timeline: releases, PR clusters, milestones, launch moments, changelog entries.
- Shipping signal: cadence, consistency, active contributors, roadmap progress, recent momentum.
- Latest receipt and repo activity.

This page should show that the project is alive and moving.

### 6. Momentum Boards

Purpose: discovery-oriented leaderboards.

Direction: use momentum to find interesting builders and projects, not just to rank status.

Content:

- Rising builders.
- Active projects.
- New releases.
- Hot streaks.
- Tool-specific boards.
- Domain-specific boards.

Favor recent velocity, rising activity, and meaningful releases over all-time PR totals so new builders can be discovered.

### 7. Talent Board

Purpose: help founders/operators find high-velocity builders.

Direction: founder/operator search, not generic ATS sourcing.

Content:

- Filters for availability, launch sprint fit, founding engineer fit, stack, domain, AI tools, recent releases, and PR velocity.
- Builder cards that lead with proof: recent receipts, project types, availability, and contact CTA.
- Copy should answer: "Who can help me ship this?"

### 8. Private Dashboard / Receipt Command Center

Purpose: signed-in builder home base.

Direction: creator/sharing command center, with compact proof analytics underneath.

Content:

- Featured receipt ready to share.
- Next best action: annotate release, publish profile update, share weekly recap.
- Public profile preview.
- Share-card studio entry point.
- Compact proof stats: PRs merged, releases made, streak, repos selected.
- Recent GitHub imports waiting for context.

The dashboard should feel less like "look at charts" and more like "turn your work into proof people can see."

### 9. Repo Picker / Proof Sources

Purpose: configure which repos count toward public proof.

Direction: simple included/excluded repo selection.

Content:

- Connected GitHub account.
- Repo list with include/exclude toggles.
- Public/private badges.
- Recent activity and last release per repo.
- Summary of included and excluded repos.
- Private repo name redaction note.
- Preview profile action.

Avoid advanced scoring weights, branch rules, labels, and complex repo grouping in this prototype.

### 10. Receipt Studio

Purpose: edit factual receipts and generate outputs from them.

Direction: factual receipt editing first, beautiful share cards as output.

Content:

- Imported GitHub evidence: release notes, PR list, contributors, repo links, timestamps.
- Receipt editor: included PRs, factual context, sensitive-detail redaction, project association.
- Public receipt preview.
- Share card outputs for LinkedIn, X, image export, and copyable receipt URL.

Share cards should be generated from receipts, not edited as disconnected marketing images.

### 11. Trust Center

Purpose: explain why users can trust PRBar with GitHub data and public scoring.

Direction: data access, scoring, privacy, and anti-gaming all matter equally.

Content:

- What PRBar reads: releases, PR metadata, repo metadata, contributor metadata, selected public signals.
- What counts: merged PRs, releases, projects, cadence, consistency, verified GitHub source links.
- What stays protected: private repo names, excluded repos, sensitive details, organization-safe controls.
- What does not count: token usage, vague claims, unverified activity.
- Anti-gaming: source links, transparent rules, weighting, anomaly review.

This should be a visible trust center, not buried fine print.

## Interaction Model

The prototype should use static sample data and client-side routing. Suggested behavior:

- Navigation buttons switch the active page/view.
- Cards link to sample builder, release, and project views.
- Talent filters update visible builder cards.
- Momentum board tabs switch between board types.
- Dashboard actions link to Repo Picker, Receipt Studio, and Public Profile Preview.
- CTAs open lightweight early-access/contact panels or route to relevant prototype views.

No real authentication, GitHub API calls, persistence, or backend should be added in this mockup.

## Visual Direction

Keep the current PRBar web style: modern, proof-forward, high-signal, and polished without feeling like a generic SaaS landing page.

Design priorities:

- Public pages should feel shareable and credible.
- Signed-in pages should feel like a working product surface, not marketing sections.
- Use dense but readable proof cards, clear tabs, segmented controls, and source-link styling.
- Avoid making token usage, follower counts, or raw popularity the visual center.
- Show receipts as the hero artifact across the experience.

## Out of Scope

- Production authentication.
- GitHub API integration.
- Real user accounts.
- Pricing page or tier design.
- Full recruiter/ATS workflow.
- Advanced repo scoring configuration.
- Social network mechanics beyond lightweight discovery affordances.

## Acceptance Criteria

- The prototype includes clickable views for all 11 pages above.
- It remains static and deployable through GitHub Pages.
- The hero copy uses "Show the world your receipts."
- The talent/employment copy uses "Receipts beat resumes."
- The private dashboard is a receipt command center, not a pure analytics dashboard.
- Release receipts are factual and GitHub-native.
- Talent Board is founder/operator-oriented.
- Momentum Boards emphasize discovery over status.
- Repo Picker stays simple.
- Trust Center covers data access, scoring, privacy, and anti-gaming.
