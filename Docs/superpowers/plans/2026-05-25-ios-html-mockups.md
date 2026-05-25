# PRBar iOS HTML Mockups Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a static, responsive HTML mockup package for the approved PRBar iOS concept before any native iOS implementation.

**Architecture:** Create a standalone `mockups/ios/` prototype with static HTML, CSS, and small vanilla JavaScript for screen/range/theme switching. Add a Node verification script that checks required screens, states, and card themes are present. Keep this separate from the existing GitHub Pages landing page so the mockup can iterate freely.

**Tech Stack:** HTML, CSS, vanilla JavaScript, Node.js built-ins, local browser verification.

---

## File Structure

- Create `mockups/ios/index.html`
  - Owns the complete mockup document, phone frames, screen sections, share-card previews, and controls.
- Create `mockups/ios/styles.css`
  - Owns layout, iPhone frame styling, native app shell styling, charts, cards, states, and responsive behavior.
- Create `mockups/ios/app.js`
  - Owns static mockup interactions: range switching, tab switching, card theme switching, privacy toggle, and repo sheet visibility.
- Create `mockups/ios/README.md`
  - Explains how to open the mockups and what screens/states are included.
- Create `scripts/verify-ios-mockups.mjs`
  - Verifies the mockup package contains all required screens, states, themes, and labels from the approved spec.
- Modify `package.json`
  - Add `verify:ios-mockups` script.

The mockup package should not depend on a bundler, framework, network, or npm package install beyond the repository's existing Node environment.

---

### Task 1: Static Mockup Shell

**Files:**
- Create: `mockups/ios/index.html`
- Create: `mockups/ios/styles.css`
- Create: `mockups/ios/app.js`
- Create: `mockups/ios/README.md`

- [ ] **Step 1: Create the mockup directory**

Run:

```bash
mkdir -p mockups/ios
```

Expected: `mockups/ios/` exists.

- [ ] **Step 2: Create `mockups/ios/index.html` with the app shell**

Add this structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PRBar iOS Mockups</title>
  <meta name="description" content="Static iOS mockups for PRBar's mobile dashboard and share-card studio.">
  <link rel="stylesheet" href="./styles.css">
</head>
<body>
  <main class="mockup-page" aria-labelledby="page-title">
    <header class="mockup-header">
      <p class="eyebrow">PRBar iOS concept</p>
      <h1 id="page-title">Mobile shipping rhythm and share cards</h1>
      <p class="header-copy">Static responsive mockups for the Day / Week / Month dashboard, card composer, and social share artifacts.</p>
    </header>

    <section class="mockup-grid" aria-label="iOS app mockup screens">
      <article class="phone-frame" data-screen="today">
        <div class="phone-screen">
          <header class="ios-topbar">
            <div>
              <p class="microcopy">Connected as</p>
              <strong>@neonwatty</strong>
            </div>
            <button class="icon-button" type="button" aria-label="Refresh PR activity">↻</button>
          </header>

          <nav class="range-control" aria-label="Activity range">
            <button class="range-button" type="button" data-range="day">Day</button>
            <button class="range-button is-active" type="button" data-range="week">Week</button>
            <button class="range-button" type="button" data-range="month">Month</button>
          </nav>

          <section class="screen-panel is-active" data-range-panel="day" aria-label="Today Day view">
            <p class="microcopy">Today</p>
            <h2>3 merged</h2>
            <p class="status-line">Work landed across 2 repos since morning.</p>
          </section>

          <section class="screen-panel is-active" data-range-panel="week" aria-label="Today Week default">
            <p class="microcopy">This week</p>
            <h2>18 merged</h2>
            <p class="status-line">+28% versus last week. Strong shipping rhythm.</p>
          </section>

          <section class="screen-panel" data-range-panel="month" aria-label="Today Month view">
            <p class="microcopy">This month</p>
            <h2>42 merged</h2>
            <p class="status-line">Best month so far, with work across 6 repos.</p>
          </section>

          <div class="mini-chart" aria-label="Pull request distribution chart">
            <span style="height: 38%"></span>
            <span style="height: 72%"></span>
            <span style="height: 56%"></span>
            <span style="height: 88%"></span>
            <span style="height: 44%"></span>
            <span style="height: 66%"></span>
            <span style="height: 92%"></span>
          </div>

          <section class="repo-mix" aria-label="Repository mix">
            <div><span class="repo-dot cyan"></span> prbar <strong>8</strong></div>
            <div><span class="repo-dot green"></span> launch-kit <strong>5</strong></div>
            <div><span class="repo-dot amber"></span> client-api <strong>3</strong></div>
          </section>

          <button class="primary-action" type="button" data-open-tab="cards">Make Card</button>
        </div>
      </article>

      <article class="phone-frame" data-screen="activity">
        <div class="phone-screen">
          <header class="section-title">
            <p class="microcopy">Activity</p>
            <h2>Repo distribution</h2>
          </header>
          <div class="large-chart" aria-label="Activity detail chart"></div>
          <button class="secondary-action" type="button" data-open-repo-sheet>Filter repositories</button>
          <section class="list-panel" aria-label="Recent merged pull requests">
            <h3>Recent PRs</h3>
            <p>Connect GitHub auth fallback</p>
            <p>Update GitHub Pages actions</p>
            <p>Expand app smoke coverage</p>
          </section>
        </div>
      </article>

      <article class="phone-frame" data-screen="cards">
        <div class="phone-screen">
          <header class="section-title">
            <p class="microcopy">Cards</p>
            <h2>Share proof of work</h2>
          </header>
          <nav class="theme-control" aria-label="Card theme">
            <button class="theme-button is-active" type="button" data-theme="clean">Clean</button>
            <button class="theme-button" type="button" data-theme="terminal">Terminal</button>
            <button class="theme-button" type="button" data-theme="hype">Hype</button>
          </nav>
          <section class="share-card clean" data-card-preview aria-label="Clean share card preview">
            <p class="microcopy">This month</p>
            <h2>42 merged PRs</h2>
            <p>A month of shipped work across 6 repos.</p>
          </section>
          <section class="composer-controls" aria-label="Card composer controls">
            <label><input type="checkbox" checked data-privacy-toggle> Show repo names</label>
            <label><input type="checkbox" checked> Show GitHub handle</label>
            <label><input type="checkbox"> Round exact count</label>
          </section>
          <button class="primary-action" type="button">Share Preview</button>
        </div>
      </article>

      <article class="phone-frame" data-screen="settings">
        <div class="phone-screen">
          <header class="section-title">
            <p class="microcopy">Settings</p>
            <h2>GitHub and privacy</h2>
          </header>
          <section class="settings-list" aria-label="Settings and auth">
            <p><strong>GitHub</strong><span>Connected</span></p>
            <p><strong>Tracked repos</strong><span>12 included</span></p>
            <p><strong>Default range</strong><span>Week</span></p>
            <p><strong>Card privacy</strong><span>Hide private repos</span></p>
          </section>
        </div>
      </article>
    </section>

    <section class="state-board" aria-label="Required mockup states">
      <h2>States</h2>
      <ul>
        <li data-state="sample-data">Sample data mode</li>
        <li data-state="connected-github">Connected GitHub mode</li>
        <li data-state="refreshing">Refreshing</li>
        <li data-state="refresh-failed">Refresh failed while previous data remains visible</li>
        <li data-state="empty-range">No PRs in selected range</li>
        <li data-state="privacy-hidden">Private repo names hidden</li>
        <li data-state="high-activity">High-activity moment detected</li>
        <li data-state="first-run">First-run connect GitHub screen</li>
      </ul>
    </section>
  </main>

  <script src="./app.js"></script>
</body>
</html>
```

- [ ] **Step 3: Create `mockups/ios/styles.css` with initial layout**

Add the first CSS pass:

```css
:root {
  color-scheme: light;
  --bg: #f4f5f7;
  --ink: #111827;
  --muted: #667085;
  --line: #d9dee7;
  --panel: #ffffff;
  --cyan: #0ea5e9;
  --green: #16a34a;
  --amber: #f59e0b;
  --dark: #101318;
  --radius: 8px;
}

* { box-sizing: border-box; }

body {
  margin: 0;
  min-width: 320px;
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
  background: var(--bg);
  color: var(--ink);
  letter-spacing: 0;
}

button,
input {
  font: inherit;
}

.mockup-page {
  width: min(1180px, calc(100% - 32px));
  margin: 0 auto;
  padding: 48px 0;
}

.mockup-header {
  max-width: 720px;
  margin-bottom: 28px;
}

.eyebrow,
.microcopy {
  margin: 0 0 6px;
  color: var(--muted);
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
}

.mockup-header h1 {
  margin: 0 0 12px;
  font-size: 42px;
  line-height: 1;
}

.header-copy {
  margin: 0;
  color: var(--muted);
  font-size: 16px;
  line-height: 1.5;
}

.mockup-grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(240px, 1fr));
  gap: 20px;
  align-items: start;
}

.phone-frame {
  padding: 10px;
  border-radius: 34px;
  background: #15171c;
  box-shadow: 0 24px 70px rgba(16, 19, 24, 0.18);
}

.phone-screen {
  min-height: 640px;
  padding: 18px;
  border-radius: 26px;
  background: var(--panel);
  overflow: hidden;
}

.ios-topbar,
.section-title {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: flex-start;
  margin-bottom: 18px;
}

.icon-button {
  width: 34px;
  height: 34px;
  border: 1px solid var(--line);
  border-radius: 50%;
  background: #fff;
}

.range-control,
.theme-control {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 4px;
  padding: 4px;
  border: 1px solid var(--line);
  border-radius: var(--radius);
  background: #f8fafc;
  margin-bottom: 18px;
}

.range-button,
.theme-button {
  min-height: 34px;
  border: 0;
  border-radius: 6px;
  background: transparent;
  color: var(--muted);
  font-weight: 700;
}

.range-button.is-active,
.theme-button.is-active {
  background: #111827;
  color: #fff;
}

.screen-panel {
  display: none;
}

.screen-panel.is-active {
  display: block;
}

.screen-panel h2,
.section-title h2,
.share-card h2 {
  margin: 0 0 8px;
  font-size: 34px;
  line-height: 1;
}

.status-line {
  margin: 0;
  color: var(--muted);
  line-height: 1.4;
}

.mini-chart,
.large-chart {
  display: flex;
  align-items: end;
  gap: 8px;
  height: 142px;
  margin: 22px 0;
  padding: 12px;
  border: 1px solid var(--line);
  border-radius: var(--radius);
  background: #f8fafc;
}

.mini-chart span {
  flex: 1;
  border-radius: 4px 4px 0 0;
  background: linear-gradient(180deg, var(--cyan), var(--green));
}

.large-chart {
  background:
    linear-gradient(90deg, var(--cyan) 18%, transparent 18% 24%, var(--green) 24% 42%, transparent 42% 48%, var(--amber) 48% 64%, transparent 64% 70%, #8b5cf6 70%);
}

.repo-mix,
.list-panel,
.composer-controls,
.settings-list,
.state-board {
  border: 1px solid var(--line);
  border-radius: var(--radius);
  background: #fff;
}

.repo-mix {
  display: grid;
  gap: 8px;
  padding: 12px;
}

.repo-mix div,
.settings-list p {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  margin: 0;
}

.repo-dot {
  display: inline-block;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  margin-right: 6px;
}

.cyan { background: var(--cyan); }
.green { background: var(--green); }
.amber { background: var(--amber); }

.primary-action,
.secondary-action {
  width: 100%;
  min-height: 44px;
  margin-top: 18px;
  border-radius: var(--radius);
  font-weight: 800;
}

.primary-action {
  border: 0;
  background: var(--ink);
  color: #fff;
}

.secondary-action {
  border: 1px solid var(--line);
  background: #fff;
  color: var(--ink);
}

.list-panel,
.composer-controls,
.settings-list {
  display: grid;
  gap: 10px;
  padding: 12px;
}

.list-panel h3,
.list-panel p {
  margin: 0;
}

.share-card {
  min-height: 260px;
  display: grid;
  align-content: end;
  gap: 8px;
  padding: 18px;
  border-radius: var(--radius);
  background: #f9fafb;
  border: 1px solid var(--line);
}

.share-card.clean { background: #ffffff; color: var(--ink); }
.share-card.terminal { background: #08090b; color: #d1fae5; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }
.share-card.hype { background: linear-gradient(135deg, #111827, #0ea5e9 55%, #16a34a); color: #ffffff; }

.state-board {
  margin-top: 24px;
  padding: 18px;
}

.state-board h2 {
  margin: 0 0 12px;
}

.state-board ul {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 10px;
  padding: 0;
  margin: 0;
  list-style: none;
}

.state-board li {
  padding: 10px;
  border-radius: var(--radius);
  background: #f8fafc;
  color: var(--muted);
  font-size: 13px;
}

@media (max-width: 1080px) {
  .mockup-grid { grid-template-columns: repeat(2, minmax(240px, 1fr)); }
  .state-board ul { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}

@media (max-width: 620px) {
  .mockup-page { width: min(100% - 20px, 390px); padding: 26px 0; }
  .mockup-header h1 { font-size: 30px; }
  .mockup-grid,
  .state-board ul { grid-template-columns: 1fr; }
}
```

- [ ] **Step 4: Create `mockups/ios/app.js` with range and theme interactions**

Add:

```js
const rangeButtons = document.querySelectorAll("[data-range]");
const rangePanels = document.querySelectorAll("[data-range-panel]");
const themeButtons = document.querySelectorAll("[data-theme]");
const cardPreview = document.querySelector("[data-card-preview]");
const privacyToggle = document.querySelector("[data-privacy-toggle]");

rangeButtons.forEach((button) => {
  button.addEventListener("click", () => {
    const range = button.dataset.range;
    rangeButtons.forEach((item) => item.classList.toggle("is-active", item === button));
    rangePanels.forEach((panel) => {
      panel.classList.toggle("is-active", panel.dataset.rangePanel === range);
    });
  });
});

themeButtons.forEach((button) => {
  button.addEventListener("click", () => {
    const theme = button.dataset.theme;
    themeButtons.forEach((item) => item.classList.toggle("is-active", item === button));
    cardPreview.className = `share-card ${theme}`;
    cardPreview.setAttribute("aria-label", `${button.textContent} share card preview`);
  });
});

privacyToggle?.addEventListener("change", () => {
  document.body.classList.toggle("privacy-hidden", !privacyToggle.checked);
});
```

- [ ] **Step 5: Create `mockups/ios/README.md`**

Add:

```markdown
# PRBar iOS Mockups

Static HTML mockups for the approved PRBar iOS app direction.

Open `mockups/ios/index.html` in a browser to review:

- Today in Day / Week / Month ranges
- Activity detail
- Cards composer
- Clean, Terminal, and Hype share-card themes
- Settings and auth concepts
- Required product states from the iOS design spec

These mockups are design artifacts. Native iOS implementation should wait until this package is reviewed.
```

- [ ] **Step 6: Open the mockup locally**

Run:

```bash
open mockups/ios/index.html
```

Expected: browser opens the static mockup page.

- [ ] **Step 7: Commit Task 1**

Run:

```bash
git add mockups/ios/index.html mockups/ios/styles.css mockups/ios/app.js mockups/ios/README.md
git commit -m "Add iOS mockup shell"
```

Expected: commit succeeds.

---

### Task 2: Complete Screen Coverage

**Files:**
- Modify: `mockups/ios/index.html`
- Modify: `mockups/ios/styles.css`

- [ ] **Step 1: Add explicit screen anchors**

In `mockups/ios/index.html`, add this navigation after `.mockup-header`:

```html
<nav class="screen-index" aria-label="Mockup screen index">
  <a href="#today-week">Today Week</a>
  <a href="#today-day">Today Day</a>
  <a href="#today-month">Today Month</a>
  <a href="#activity-detail">Activity</a>
  <a href="#repo-filter">Repo Filter</a>
  <a href="#card-entry">Card Entry</a>
  <a href="#card-composer">Composer</a>
  <a href="#card-clean">Clean Card</a>
  <a href="#card-terminal">Terminal Card</a>
  <a href="#card-hype">Hype Card</a>
  <a href="#cards-gallery">Gallery</a>
  <a href="#settings-auth">Settings</a>
</nav>
```

- [ ] **Step 2: Add missing standalone mockup sections**

Append these sections before `.state-board`:

```html
<section class="flow-board" aria-label="Standalone iOS mockup screens">
  <article id="today-week" data-required-screen="today-week">
    <h2>Today, Week default</h2>
    <p>18 merged this week, +28% versus last week, with a Make Card action.</p>
  </article>
  <article id="today-day" data-required-screen="today-day">
    <h2>Today, Day view</h2>
    <p>3 merged today, chronological activity, and last refresh status.</p>
  </article>
  <article id="today-month" data-required-screen="today-month">
    <h2>Today, Month view</h2>
    <p>42 merged this month, best stretch, top repos, and Share this month action.</p>
  </article>
  <article id="activity-detail" data-required-screen="activity-detail">
    <h2>Activity detail</h2>
    <p>Larger chart, repo breakdown, recent PRs, and comparison to previous period.</p>
  </article>
  <article id="repo-filter" data-required-screen="repo-filter">
    <h2>Repo filter sheet</h2>
    <p>Search, include/exclude toggles, repo color dots, and private indicators.</p>
  </article>
  <article id="card-entry" data-required-screen="card-entry">
    <h2>Card entry point</h2>
    <p>Start from a stat, period, or high-activity moment.</p>
  </article>
  <article id="card-composer" data-required-screen="card-composer">
    <h2>Card composer</h2>
    <p>Theme, range, metric focus, privacy, exact count, and caption controls.</p>
  </article>
  <article id="card-clean" data-required-screen="card-clean">
    <h2>Clean card preview</h2>
    <p>Professional default for LinkedIn, GitHub, and founder updates.</p>
  </article>
  <article id="card-terminal" data-required-screen="card-terminal">
    <h2>Terminal card preview</h2>
    <p>Dark technical treatment with monospaced accents.</p>
  </article>
  <article id="card-hype" data-required-screen="card-hype">
    <h2>Hype card preview</h2>
    <p>Expressive share-only style for high-energy moments.</p>
  </article>
  <article id="cards-gallery" data-required-screen="cards-gallery">
    <h2>Cards gallery</h2>
    <p>Saved cards, recreate from period, and reshare actions.</p>
  </article>
  <article id="settings-auth" data-required-screen="settings-auth">
    <h2>Settings and auth</h2>
    <p>GitHub connection, tracked repos, refresh behavior, and privacy defaults.</p>
  </article>
</section>
```

- [ ] **Step 3: Style the screen index and flow board**

Append to `mockups/ios/styles.css`:

```css
.screen-index {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin: 0 0 24px;
}

.screen-index a {
  min-height: 34px;
  display: inline-flex;
  align-items: center;
  padding: 0 10px;
  border: 1px solid var(--line);
  border-radius: var(--radius);
  background: #fff;
  color: var(--ink);
  text-decoration: none;
  font-size: 13px;
  font-weight: 700;
}

.flow-board {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 14px;
  margin-top: 24px;
}

.flow-board article {
  min-height: 140px;
  padding: 14px;
  border: 1px solid var(--line);
  border-radius: var(--radius);
  background: #fff;
}

.flow-board h2 {
  margin: 0 0 8px;
  font-size: 18px;
}

.flow-board p {
  margin: 0;
  color: var(--muted);
  font-size: 14px;
  line-height: 1.45;
}

@media (max-width: 1080px) {
  .flow-board { grid-template-columns: repeat(2, minmax(0, 1fr)); }
}

@media (max-width: 620px) {
  .flow-board { grid-template-columns: 1fr; }
}
```

- [ ] **Step 4: Commit Task 2**

Run:

```bash
git add mockups/ios/index.html mockups/ios/styles.css
git commit -m "Expand iOS mockup screen coverage"
```

Expected: commit succeeds.

---

### Task 3: Card Theme Fidelity

**Files:**
- Modify: `mockups/ios/index.html`
- Modify: `mockups/ios/styles.css`
- Modify: `mockups/ios/app.js`

- [ ] **Step 1: Add all five theme buttons**

Replace the theme control in `mockups/ios/index.html` with:

```html
<nav class="theme-control five-up" aria-label="Card theme">
  <button class="theme-button is-active" type="button" data-theme="clean">Clean</button>
  <button class="theme-button" type="button" data-theme="terminal">Terminal</button>
  <button class="theme-button" type="button" data-theme="launch">Launch</button>
  <button class="theme-button" type="button" data-theme="hype">Hype</button>
  <button class="theme-button" type="button" data-theme="minimal">Minimal</button>
</nav>
```

- [ ] **Step 2: Replace the share card preview content**

Replace the existing `section[data-card-preview]` with:

```html
<section class="share-card clean" data-card-preview aria-label="Clean share card preview">
  <div>
    <p class="microcopy" data-card-range>This month</p>
    <h2 data-card-title>42 merged PRs</h2>
    <p data-card-caption>A month of shipped work across 6 repos.</p>
  </div>
  <div class="card-bars" aria-label="Card distribution chart">
    <span style="height: 30%"></span>
    <span style="height: 64%"></span>
    <span style="height: 46%"></span>
    <span style="height: 80%"></span>
    <span style="height: 58%"></span>
    <span style="height: 92%"></span>
  </div>
  <footer>
    <span>@neonwatty</span>
    <span>PRBar</span>
  </footer>
</section>
```

- [ ] **Step 3: Add theme copy to `mockups/ios/app.js`**

Replace the theme button handler setup with:

```js
const themeCopy = {
  clean: {
    range: "This month",
    title: "42 merged PRs",
    caption: "A month of shipped work across 6 repos."
  },
  terminal: {
    range: "range=month",
    title: "git merged --count 42",
    caption: "shipping rhythm: strong"
  },
  launch: {
    range: "May 2026",
    title: "A month of shipped work",
    caption: "42 merged PRs moved the release forward."
  },
  hype: {
    range: "Big merge month",
    title: "42 PRs landed",
    caption: "High-velocity work across the stack."
  },
  minimal: {
    range: "May 2026",
    title: "42 merged",
    caption: "@neonwatty"
  }
};

themeButtons.forEach((button) => {
  button.addEventListener("click", () => {
    const theme = button.dataset.theme;
    const copy = themeCopy[theme];
    themeButtons.forEach((item) => item.classList.toggle("is-active", item === button));
    cardPreview.className = `share-card ${theme}`;
    cardPreview.setAttribute("aria-label", `${button.textContent} share card preview`);
    cardPreview.querySelector("[data-card-range]").textContent = copy.range;
    cardPreview.querySelector("[data-card-title]").textContent = copy.title;
    cardPreview.querySelector("[data-card-caption]").textContent = copy.caption;
  });
});
```

- [ ] **Step 4: Add CSS for Launch, Minimal, and card bars**

Append:

```css
.five-up {
  grid-template-columns: repeat(5, 1fr);
}

.five-up .theme-button {
  font-size: 11px;
}

.share-card.launch {
  background: #fff7ed;
  color: #1f2937;
  border-color: #fed7aa;
}

.share-card.minimal {
  background: #ffffff;
  color: #111827;
}

.share-card.minimal .card-bars,
.share-card.minimal [data-card-caption] {
  display: none;
}

.card-bars {
  display: flex;
  align-items: end;
  gap: 7px;
  height: 78px;
}

.card-bars span {
  flex: 1;
  border-radius: 4px;
  background: currentColor;
  opacity: 0.72;
}

.share-card footer {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  font-size: 12px;
  font-weight: 800;
}
```

- [ ] **Step 5: Commit Task 3**

Run:

```bash
git add mockups/ios/index.html mockups/ios/styles.css mockups/ios/app.js
git commit -m "Refine iOS share card themes"
```

Expected: commit succeeds.

---

### Task 4: Verification Script

**Files:**
- Create: `scripts/verify-ios-mockups.mjs`
- Modify: `package.json`

- [ ] **Step 1: Create `scripts/verify-ios-mockups.mjs`**

Add:

```js
import { readFileSync } from "node:fs";

const html = readFileSync("mockups/ios/index.html", "utf8");
const css = readFileSync("mockups/ios/styles.css", "utf8");
const js = readFileSync("mockups/ios/app.js", "utf8");

const requiredScreens = [
  "today-week",
  "today-day",
  "today-month",
  "activity-detail",
  "repo-filter",
  "card-entry",
  "card-composer",
  "card-clean",
  "card-terminal",
  "card-hype",
  "cards-gallery",
  "settings-auth"
];

const requiredStates = [
  "sample-data",
  "connected-github",
  "refreshing",
  "refresh-failed",
  "empty-range",
  "privacy-hidden",
  "high-activity",
  "first-run"
];

const requiredThemes = ["clean", "terminal", "launch", "hype", "minimal"];
const requiredRanges = ["day", "week", "month"];

function assertIncludes(source, needle, label) {
  if (!source.includes(needle)) {
    throw new Error(`Missing ${label}: ${needle}`);
  }
}

for (const screen of requiredScreens) {
  assertIncludes(html, `data-required-screen="${screen}"`, "screen");
}

for (const state of requiredStates) {
  assertIncludes(html, `data-state="${state}"`, "state");
}

for (const theme of requiredThemes) {
  assertIncludes(html, `data-theme="${theme}"`, "theme button");
  assertIncludes(css, `.share-card.${theme}`, "theme style");
  assertIncludes(js, `${theme}:`, "theme script copy");
}

for (const range of requiredRanges) {
  assertIncludes(html, `data-range="${range}"`, "range button");
  assertIncludes(html, `data-range-panel="${range}"`, "range panel");
}

assertIncludes(html, "Day / Week / Month", "approved range language");
assertIncludes(html, "Share proof of work", "cards positioning");
assertIncludes(html, "Hide private repos", "privacy default");

console.log("iOS mockup verification passed");
```

- [ ] **Step 2: Add the npm script**

Modify `package.json` scripts to:

```json
"scripts": {
  "release": "semantic-release",
  "verify:ios-mockups": "node scripts/verify-ios-mockups.mjs"
}
```

- [ ] **Step 3: Run the verification script**

Run:

```bash
npm run verify:ios-mockups
```

Expected output includes:

```text
iOS mockup verification passed
```

- [ ] **Step 4: Commit Task 4**

Run:

```bash
git add package.json scripts/verify-ios-mockups.mjs
git commit -m "Add iOS mockup verification"
```

Expected: commit succeeds.

---

### Task 5: Browser Review Pass

**Files:**
- Modify as needed: `mockups/ios/index.html`
- Modify as needed: `mockups/ios/styles.css`
- Modify as needed: `mockups/ios/app.js`

- [ ] **Step 1: Start a local static server**

Run:

```bash
python3 -m http.server 4173
```

Expected output includes:

```text
Serving HTTP on
```

- [ ] **Step 2: Open the mockups in the browser**

Open:

```text
http://localhost:4173/mockups/ios/
```

Expected: page loads with four phone frames and the standalone screen board.

- [ ] **Step 3: Verify desktop viewport**

At a desktop viewport around `1440 x 1000`, verify:

- header text is visible and not overlapping
- four phone frames fit in a grid
- each phone frame has stable dimensions
- charts are nonblank
- `Day / Week / Month` buttons switch Today content
- card theme buttons switch the preview
- state board is visible

- [ ] **Step 4: Verify mobile viewport**

At a mobile viewport around `390 x 844`, verify:

- content stacks to one column
- phone frames fit within the viewport width
- button text does not overflow
- chart bars remain visible
- screen index wraps cleanly
- state board items do not overlap

- [ ] **Step 5: Fix any visual issues found**

If text overflows inside buttons, add this CSS:

```css
.range-button,
.theme-button,
.screen-index a {
  overflow-wrap: anywhere;
  line-height: 1.1;
}
```

If phone frames exceed mobile width, add this CSS:

```css
.phone-frame {
  width: 100%;
  max-width: 390px;
  margin-inline: auto;
}
```

If the five theme buttons feel too cramped, replace `.five-up` with horizontally scrollable controls:

```css
.theme-control.five-up {
  display: flex;
  overflow-x: auto;
}

.theme-control.five-up .theme-button {
  min-width: 72px;
}
```

- [ ] **Step 6: Re-run verification**

Run:

```bash
npm run verify:ios-mockups
```

Expected output includes:

```text
iOS mockup verification passed
```

- [ ] **Step 7: Commit Task 5**

Run:

```bash
git add mockups/ios/index.html mockups/ios/styles.css mockups/ios/app.js
git commit -m "Polish iOS mockup responsive layout"
```

Expected: commit succeeds.

---

## Final Verification

- [ ] Run:

```bash
npm run verify:ios-mockups
```

Expected output:

```text
iOS mockup verification passed
```

- [ ] Run:

```bash
git status --short
```

Expected: no uncommitted changes, unless the worker intentionally leaves review screenshots or notes unstaged.

- [ ] Confirm the mockup review URL:

```text
http://localhost:4173/mockups/ios/
```

Expected: the user can review the HTML mockup package in a browser.

---

## Scope Notes

This plan intentionally does not create native iOS targets, SwiftUI views, OAuth flows, backend profile pages, or real GitHub data plumbing. Those belong after the HTML mockup package has been reviewed and approved.

## Self-Review

Spec coverage:

- Hybrid private dashboard plus card studio is covered by Tasks 1-3.
- Day / Week / Month range model is covered by Tasks 1 and 4.
- Required 12 mockup screens are covered by Task 2 and verified in Task 4.
- Required states are covered by Task 1 and verified in Task 4.
- Clean, Terminal, Hype, Launch, and Minimal themes are covered by Task 3.
- HTML-before-native gate is preserved in the scope notes and README.

Placeholder scan:

- No unfinished placeholder markers or deferred implementation notes are used.

Type and selector consistency:

- `data-range`, `data-range-panel`, `data-theme`, `data-card-preview`, `data-required-screen`, and `data-state` are introduced before they are verified.
- Theme names match across HTML, CSS, JavaScript, and the verification script.
