# PRBar iOS Interactive Prototype Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the static iOS mockup board with a complete interactive mobile HTML prototype.

**Architecture:** Keep the prototype framework-free. Use `mockups/ios/index.html` for a single phone app shell, `mockups/ios/styles.css` for the mobile UI system, `mockups/ios/app.js` for fixture data, app state, rendering, and events, and `scripts/verify-ios-mockups.mjs` for structural and copy checks.

**Tech Stack:** HTML, CSS, vanilla JavaScript, Node.js built-ins, Playwright CLI for browser screenshots.

---

### Task 1: Interactive App Shell

**Files:**
- Modify: `mockups/ios/index.html`
- Modify: `mockups/ios/styles.css`
- Modify: `mockups/ios/app.js`

- [ ] Replace the static screen board with one phone app shell.
- [ ] Add bottom navigation for Today, Activity, Releases, Cards, and More.
- [ ] Add screen containers rendered by JavaScript.
- [ ] Keep a desktop review wrapper around the phone shell.

### Task 2: Fixture Data And State

**Files:**
- Modify: `mockups/ios/app.js`

- [ ] Add fixture repositories, merged PRs, GitHub Releases, settings, privacy state, and card draft state.
- [ ] Implement included-repo filtering.
- [ ] Implement Day / Week / Month range state.
- [ ] Implement navigation state and More submenu state.

### Task 3: Screen Behavior

**Files:**
- Modify: `mockups/ios/app.js`
- Modify: `mockups/ios/styles.css`

- [ ] Render Today from fixture PRs and selected range.
- [ ] Render Activity from included repositories.
- [ ] Render Releases from included repositories.
- [ ] Render Cards from activity or selected release.
- [ ] Render More, Repos, Settings, Privacy, Sample Data, and About.
- [ ] Wire Make Card, Make Release Card, Open on GitHub, Copy release notes, repo inclusion, theme, and privacy controls.

### Task 4: Verification

**Files:**
- Modify: `scripts/verify-ios-mockups.mjs`

- [ ] Verify primary nav labels.
- [ ] Verify More menu labels.
- [ ] Verify fixture-backed GitHub Releases copy.
- [ ] Verify repo inclusion copy.
- [ ] Verify card source, theme, and privacy copy.
- [ ] Run `npm run verify:ios-mockups`.
- [ ] Run JavaScript syntax checks.
- [ ] Capture desktop and mobile screenshots with Playwright.

### Task 5: Commit

**Files:**
- Modify: `mockups/ios/index.html`
- Modify: `mockups/ios/styles.css`
- Modify: `mockups/ios/app.js`
- Modify: `mockups/ios/README.md`
- Modify: `scripts/verify-ios-mockups.mjs`

- [ ] Commit the completed prototype.

---

## Self-Review

Spec coverage:

- Bottom navigation and More menu are covered by Tasks 1 and 3.
- Fixture-backed GitHub Releases are covered by Tasks 2 and 3.
- Repo inclusion state affecting Activity, Releases, and Cards is covered by Tasks 2 and 3.
- Card source, theme, and privacy interactions are covered by Task 3.
- Verification requirements are covered by Task 4.

Placeholder scan:

- No unfinished placeholder markers or deferred implementation notes are used.

Scope check:

- The plan does not include native iOS, real GitHub auth, real API calls, backend storage, public profiles, or AI summaries.
