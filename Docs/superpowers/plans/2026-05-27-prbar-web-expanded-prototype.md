# PRBar Web Expanded Prototype Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand `mockups/web/` into a static, connected, single-page HTML/CSS/JavaScript prototype with the 11 approved PRBar web surfaces.

**Architecture:** Keep the mockup deployable on GitHub Pages as static files. `index.html` owns the document shell and empty view mount points, `app.js` owns sample data, client-side routing, rendering, filters, and small interactions, and `styles.css` owns all layout and responsive styling. No backend, no GitHub API calls, no real auth, and no persistence.

**Tech Stack:** Static HTML, vanilla JavaScript, CSS, local `python3 -m http.server`, bundled Playwright for smoke verification.

---

## File Structure

- Modify: `mockups/web/index.html`
  - Keep `<head>`, brand header, top navigation, main app shell, modal shell, and script include.
  - Replace long inline page sections with routed containers.
- Modify: `mockups/web/app.js`
  - Replace current small leaderboard/talent script with static data, route definitions, render functions, event delegation, filters, and modal behavior.
- Modify: `mockups/web/styles.css`
  - Preserve the current visual language while adding reusable app-page, receipt, dashboard, board, profile, studio, repo, and trust layouts.
- Modify: `mockups/web/README.md`
  - Update the description and local verification instructions for the expanded prototype.
- Create: `mockups/web/smoke-test.js`
  - Browser smoke test for all routes, required copy, click interactions, and mobile horizontal overflow.

## Route Inventory

Use hash routes so the prototype remains a single static file:

- `#/home`
- `#/network`
- `#/profile`
- `#/receipt`
- `#/project`
- `#/boards`
- `#/talent`
- `#/dashboard`
- `#/repos`
- `#/studio`
- `#/trust`

Default route: `#/home`.

---

### Task 1: Add Static Data And Route Skeleton

**Files:**
- Modify: `mockups/web/app.js`

- [ ] **Step 1: Replace the current script with route/data skeleton**

Replace `mockups/web/app.js` with:

```javascript
const routes = [
  { id: "home", label: "Home", path: "#/home" },
  { id: "network", label: "Proof Network", path: "#/network" },
  { id: "boards", label: "Momentum Boards", path: "#/boards" },
  { id: "talent", label: "Talent", path: "#/talent" },
  { id: "dashboard", label: "Dashboard", path: "#/dashboard" },
  { id: "trust", label: "Trust", path: "#/trust" },
];

const secondaryRoutes = [
  { id: "profile", label: "Builder Profile", path: "#/profile" },
  { id: "receipt", label: "Release Receipt", path: "#/receipt" },
  { id: "project", label: "Project Page", path: "#/project" },
  { id: "repos", label: "Repo Picker", path: "#/repos" },
  { id: "studio", label: "Receipt Studio", path: "#/studio" },
];

const sample = {
  builder: {
    handle: "@maya.codes",
    name: "Maya Chen",
    headline: "AI-native iOS + SaaS builder",
    availability: "Available for founding engineer or 2-week launch sprint work",
    stack: ["SwiftUI", "Next.js", "Supabase", "Stripe"],
    tools: ["Claude Code", "Codex", "Cursor"],
    domains: ["mobile", "SaaS", "AI onboarding"],
    stats: [
      { label: "PRs quarter", value: "118" },
      { label: "Releases", value: "14" },
      { label: "Projects", value: "11" },
      { label: "Day streak", value: "9" },
    ],
  },
  release: {
    title: "SideProject Radar v2.1",
    repo: "maya/sideproject-radar",
    tag: "v2.1.0",
    published: "May 24, 2026",
    summary: "8 PRs merged / 3 contributors / 42 files changed",
    notes: [
      "Added launch feed filters for active side projects.",
      "Shipped GitHub release import and proof-card exports.",
      "Improved onboarding instrumentation and empty states.",
    ],
    prs: [
      { number: 184, title: "Add release receipt importer", author: "@maya.codes", merged: "May 24", labels: ["release", "github"] },
      { number: 181, title: "Create project momentum filters", author: "@rio.ai", merged: "May 23", labels: ["feed"] },
      { number: 179, title: "Polish share-card export states", author: "@nora.ship", merged: "May 22", labels: ["studio"] },
    ],
  },
  projects: [
    { name: "SideProject Radar", releases: "6 releases quarter", prs: "42 PRs", cadence: "weekly", status: "cadence improving" },
    { name: "AI Onboarding Kit", releases: "3 releases month", prs: "21 PRs", cadence: "twice weekly", status: "launch sprint" },
    { name: "PromptOps Mobile", releases: "4 releases quarter", prs: "35 PRs", cadence: "weekly", status: "active beta" },
  ],
  feed: [
    { type: "Release", title: "Maya shipped SideProject Radar v2.1", proof: "8 PRs / 3 contributors / v2.1.0", route: "#/receipt" },
    { type: "Project", title: "AI Onboarding Kit picked up weekly release cadence", proof: "3 releases / 21 PRs / active roadmap", route: "#/project" },
    { type: "Builder", title: "Devon is available for an iOS launch sprint", proof: "11-day streak / 2 releases / SwiftUI", route: "#/profile" },
  ],
  boards: {
    rising: [
      { rank: 1, name: "@maya.codes", proof: "4 releases this week", momentum: "+38%" },
      { rank: 2, name: "@devon.codes", proof: "11-day iOS streak", momentum: "+26%" },
      { rank: 3, name: "@rhea.builds", proof: "3 launch-sprint projects", momentum: "+19%" },
    ],
    projects: [
      { rank: 1, name: "SideProject Radar", proof: "6 releases this quarter", momentum: "+31%" },
      { rank: 2, name: "PromptOps Mobile", proof: "35 PRs this quarter", momentum: "+22%" },
      { rank: 3, name: "AI Onboarding Kit", proof: "weekly release cadence", momentum: "+18%" },
    ],
    releases: [
      { rank: 1, name: "SideProject Radar v2.1", proof: "8 PRs / 3 contributors", momentum: "new" },
      { rank: 2, name: "PromptOps Mobile 1.4", proof: "5 PRs / App Store release", momentum: "new" },
      { rank: 3, name: "AI Onboarding Kit 0.9", proof: "7 PRs / beta launch", momentum: "new" },
    ],
  },
  talent: [
    { handle: "@nora.ship", fit: "Launch sprint SaaS builder", proof: "3 releases this month", tags: ["available", "saas", "launch"] },
    { handle: "@devon.codes", fit: "SwiftUI founding-engineer fit", proof: "11-day streak, 2 iOS releases", tags: ["available", "mobile", "founding"] },
    { handle: "@rhea.builds", fit: "AI onboarding and billing flows", proof: "21 PRs across 3 projects", tags: ["saas", "ai-tools", "launch"] },
  ],
  repos: [
    { name: "sideproject-radar", visibility: "public", included: true, activity: "8 PRs this week", release: "v2.1.0" },
    { name: "ai-onboarding-kit", visibility: "public", included: true, activity: "5 PRs this week", release: "v0.9.0" },
    { name: "client-ios-redacted", visibility: "private", included: true, activity: "12 PRs this month", release: "private" },
    { name: "scratch-prompts", visibility: "private", included: false, activity: "no releases", release: "none" },
  ],
};

const app = document.querySelector("#app");
const nav = document.querySelector(".nav-links");
const headerAction = document.querySelector(".header-action");
const modal = document.querySelector("#early-access-modal");

function routeIdFromHash() {
  const id = window.location.hash.replace("#/", "");
  return [...routes, ...secondaryRoutes].some((route) => route.id === id) ? id : "home";
}

function linkTo(routeId, label, className = "text-link") {
  return `<a class="${className}" href="#/${routeId}">${label}</a>`;
}

function tags(items) {
  return `<div class="tag-row">${items.map((item) => `<span>${item}</span>`).join("")}</div>`;
}

function render() {
  const routeId = routeIdFromHash();
  document.body.dataset.route = routeId;
  nav.innerHTML = routes.map((route) => `<a href="${route.path}" data-route-link="${route.id}">${route.label}</a>`).join("");
  document.querySelectorAll("[data-route-link]").forEach((link) => {
    link.classList.toggle("active", link.dataset.routeLink === routeId);
  });
  app.innerHTML = renderRoute(routeId);
}

function renderRoute(routeId) {
  const views = {
    home: renderHome,
    network: renderNetwork,
    profile: renderProfile,
    receipt: renderReceipt,
    project: renderProject,
    boards: renderBoards,
    talent: renderTalent,
    dashboard: renderDashboard,
    repos: renderRepos,
    studio: renderStudio,
    trust: renderTrust,
  };
  return views[routeId]();
}
```

- [ ] **Step 2: Add temporary view functions so the app runs**

Append this temporary implementation at the end of `mockups/web/app.js`:

```javascript
function renderHome() {
  return `<section class="app-page"><h1>Show the world your receipts.</h1><p><strong>Token usage does not count.</strong> Features shipped, PRs merged, releases made, projects launched. PRBar turns your GitHub activity into proof you can share.</p></section>`;
}
function renderNetwork() { return `<section class="app-page"><h1>Proof Network</h1></section>`; }
function renderProfile() { return `<section class="app-page"><h1>Receipts beat resumes.</h1></section>`; }
function renderReceipt() { return `<section class="app-page"><h1>Release Receipt</h1></section>`; }
function renderProject() { return `<section class="app-page"><h1>Project Page</h1></section>`; }
function renderBoards() { return `<section class="app-page"><h1>Momentum Boards</h1></section>`; }
function renderTalent() { return `<section class="app-page"><h1>Who can help me ship this?</h1></section>`; }
function renderDashboard() { return `<section class="app-page"><h1>Receipt Command Center</h1></section>`; }
function renderRepos() { return `<section class="app-page"><h1>Proof Sources</h1></section>`; }
function renderStudio() { return `<section class="app-page"><h1>Receipt Studio</h1></section>`; }
function renderTrust() { return `<section class="app-page"><h1>Trust Center</h1></section>`; }

window.addEventListener("hashchange", render);
headerAction.addEventListener("click", (event) => {
  event.preventDefault();
  modal.hidden = false;
});
document.querySelector("[data-close-modal]").addEventListener("click", () => {
  modal.hidden = true;
});
if (!window.location.hash) {
  window.location.hash = "#/home";
} else {
  render();
}
```

- [ ] **Step 3: Verify the skeleton runs**

Run:

```bash
python3 -m http.server 4181 --directory mockups/web
```

In another terminal:

```bash
curl -sL http://127.0.0.1:4181/ | rg "PRBar Web Mockup"
```

Expected: the title markup is returned. The JavaScript views will be browser-rendered in later smoke tests.

- [ ] **Step 4: Commit**

```bash
git add mockups/web/app.js
git commit -m "Build routed PRBar web prototype skeleton"
```

---

### Task 2: Simplify HTML Into A Routed App Shell

**Files:**
- Modify: `mockups/web/index.html`

- [ ] **Step 1: Replace `<body>` content with app shell**

In `mockups/web/index.html`, keep the existing `<head>` and replace the `<body>` with:

```html
  <body>
    <header class="site-header" aria-label="Primary">
      <a class="brand" href="#/home" aria-label="PRBar home">
        <span class="brand-mark" aria-hidden="true">PR</span>
        <span>PRBar</span>
      </a>
      <nav class="nav-links" aria-label="Sections"></nav>
      <a class="header-action" href="#/early-access">Join early access</a>
    </header>

    <main id="app" tabindex="-1"></main>

    <div class="modal-backdrop" id="early-access-modal" hidden>
      <section class="modal-panel" role="dialog" aria-modal="true" aria-labelledby="early-access-title">
        <button class="icon-button modal-close" type="button" data-close-modal aria-label="Close early access panel">
          <svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 6l12 12M18 6 6 18" /></svg>
        </button>
        <span class="eyebrow">Early access</span>
        <h2 id="early-access-title">Claim your proof profile.</h2>
        <p>Connect GitHub, select the repos that count, and turn releases into receipts you can share with founders, collaborators, and the world.</p>
        <div class="modal-actions">
          <a class="primary-action" href="#/dashboard" data-close-modal>Preview dashboard</a>
          <a class="secondary-action" href="#/talent" data-close-modal>Scout builders</a>
        </div>
      </section>
    </div>

    <script src="./app.js"></script>
  </body>
```

- [ ] **Step 2: Update modal close handling to support CTA links**

In `mockups/web/app.js`, replace the single `document.querySelector("[data-close-modal]").addEventListener` block with:

```javascript
document.querySelectorAll("[data-close-modal]").forEach((control) => {
  control.addEventListener("click", () => {
    modal.hidden = true;
  });
});
```

- [ ] **Step 3: Verify key shell elements exist**

Run:

```bash
curl -sL http://127.0.0.1:4181/ | rg "id=\"app\"|early-access-modal|Join early access"
```

Expected: all three strings are printed.

- [ ] **Step 4: Commit**

```bash
git add mockups/web/index.html mockups/web/app.js
git commit -m "Convert PRBar mockup to routed app shell"
```

---

### Task 3: Implement Public Pages

**Files:**
- Modify: `mockups/web/app.js`

- [ ] **Step 1: Replace temporary public view functions**

Replace `renderHome`, `renderNetwork`, `renderProfile`, `renderReceipt`, `renderProject`, and `renderBoards` with complete render functions. Keep the function names exactly as defined in Task 1.

```javascript
function statGrid(stats) {
  return `<div class="metric-grid">${stats.map((stat) => `<div><strong>${stat.value}</strong><span>${stat.label}</span></div>`).join("")}</div>`;
}

function proofCard(title, body, routeId, meta = "Verified GitHub") {
  return `<article class="proof-card"><span>${meta}</span><h3>${title}</h3><p>${body}</p>${linkTo(routeId, "Open receipt", "card-link")}</article>`;
}

function renderHome() {
  return `
    <section class="hero app-hero">
      <div class="hero-content">
        <p class="hero-label">Verified GitHub velocity for AI-native builders</p>
        <h1>Show the world your receipts.</h1>
        <p class="hero-lede"><strong>Token usage does not count.</strong> Features shipped, PRs merged, releases made, projects launched. PRBar turns your GitHub activity into proof you can share.</p>
        <div class="hero-actions">
          <a class="primary-action" href="#/dashboard">Claim your profile</a>
          <a class="secondary-action" href="#/talent">Scout builders</a>
        </div>
      </div>
      <div class="receipt-hero-card">
        <span>Featured receipt</span>
        <h2>${sample.release.title}</h2>
        <p>${sample.release.summary}</p>
        ${linkTo("receipt", "View release receipt", "card-link")}
      </div>
    </section>
    <section class="section-pad">
      <div class="section-heading compact"><span>Proof surfaces</span><h2>Receipts for builders, projects, and releases.</h2></div>
      <div class="card-grid three">
        ${proofCard("Career proof profile", "Employment signal backed by selected repos, releases, PR velocity, stack, and availability.", "profile")}
        ${proofCard("Project operating history", "A proof timeline showing releases, milestones, cadence, contributors, and roadmap momentum.", "project")}
        ${proofCard("Momentum discovery", "Find rising builders and active projects through recent verified shipping activity.", "boards")}
      </div>
    </section>
  `;
}

function renderNetwork() {
  return `
    <section class="app-page">
      <div class="page-heading"><span>Proof Network</span><h1>People and projects first. GitHub proof underneath.</h1><p>Browse builders and projects with verified release, PR, repo, and timestamp evidence attached.</p></div>
      <div class="feed-layout">
        <div class="feed-list">${sample.feed.map((item) => `<article class="feed-card"><span>${item.type}</span><h3>${item.title}</h3><p>${item.proof}</p><a class="card-link" href="${item.route}">Inspect proof</a></article>`).join("")}</div>
        <aside class="source-panel"><span>Source-of-truth</span><h2>${sample.release.repo}</h2><p>Release tag ${sample.release.tag} · ${sample.release.published}</p><p>PR links, contributors, timestamps, and verification state stay attached to each receipt.</p></aside>
      </div>
    </section>
  `;
}

function renderProfile() {
  return `
    <section class="app-page">
      <div class="profile-shell">
        <div class="profile-main">
          <span class="eyebrow">Career proof profile</span>
          <h1>Receipts beat resumes.</h1>
          <p>${sample.builder.name} is an ${sample.builder.headline}. ${sample.builder.availability}.</p>
          ${tags([...sample.builder.stack, ...sample.builder.tools])}
          ${statGrid(sample.builder.stats)}
        </div>
        <aside class="profile-side"><h2>Hiring signal</h2><p>${sample.builder.domains.join(" / ")}</p><a class="primary-action" href="#/talent">Contact through Talent Board</a></aside>
      </div>
      <div class="card-grid two">
        ${proofCard(sample.release.title, sample.release.summary, "receipt", "Featured receipt")}
        ${proofCard("SideProject Radar", "6 releases this quarter with weekly cadence and active roadmap progress.", "project", "Selected project")}
      </div>
    </section>
  `;
}

function renderReceipt() {
  return `
    <section class="app-page">
      <div class="receipt-layout">
        <div class="receipt-main">
          <span class="eyebrow">Release receipt</span>
          <h1>${sample.release.title}</h1>
          <p>${sample.release.repo} · ${sample.release.tag} · ${sample.release.published}</p>
          <div class="receipt-notes">${sample.release.notes.map((note) => `<p>${note}</p>`).join("")}</div>
        </div>
        <aside class="receipt-proof"><h2>${sample.release.summary}</h2><p>Imported from GitHub release notes with source links attached.</p><a class="secondary-action" href="#/studio">Open in Receipt Studio</a></aside>
      </div>
      <div class="table-card"><h2>Merged PRs</h2>${sample.release.prs.map((pr) => `<article class="pr-row"><strong>#${pr.number}</strong><span>${pr.title}</span><span>${pr.author}</span><span>${pr.merged}</span></article>`).join("")}</div>
    </section>
  `;
}

function renderProject() {
  return `
    <section class="app-page">
      <div class="page-heading"><span>Project page</span><h1>SideProject Radar operating history.</h1><p>Proof timeline plus traction-style shipping signal.</p></div>
      <div class="project-layout">
        <div class="timeline">${["v2.1 release", "GitHub importer", "Launch feed filters", "Share-card exports"].map((item) => `<article><span>Verified milestone</span><h3>${item}</h3><p>Linked to releases, merged PR clusters, and project momentum.</p></article>`).join("")}</div>
        <aside class="traction-panel"><h2>Shipping signal</h2><p>6 releases this quarter · 42 PRs · 3 active repos · cadence improving.</p>${linkTo("receipt", "Latest receipt", "card-link")}</aside>
      </div>
    </section>
  `;
}

function renderBoards() {
  return `
    <section class="app-page">
      <div class="page-heading"><span>Momentum Boards</span><h1>Discover builders and projects with current momentum.</h1><p>Recent velocity matters more than all-time totals.</p></div>
      <div class="segmented" role="tablist" aria-label="Momentum board type">
        <button class="active" type="button" data-board="rising">Rising builders</button>
        <button type="button" data-board="projects">Active projects</button>
        <button type="button" data-board="releases">New releases</button>
      </div>
      <div class="leaderboard" data-board-output></div>
    </section>
  `;
}
```

- [ ] **Step 2: Verify static copy exists in source**

Run:

```bash
rg "Show the world your receipts|Receipts beat resumes|Release receipt|Momentum Boards" mockups/web/app.js
```

Expected: all four phrases are present.

- [ ] **Step 3: Commit**

```bash
git add mockups/web/app.js
git commit -m "Add public PRBar prototype pages"
```

---

### Task 4: Implement Builder And Trust Pages

**Files:**
- Modify: `mockups/web/app.js`

- [ ] **Step 1: Replace temporary builder/trust view functions**

Replace `renderTalent`, `renderDashboard`, `renderRepos`, `renderStudio`, and `renderTrust` with:

```javascript
function renderTalent() {
  return `
    <section class="app-page">
      <div class="page-heading"><span>AI Builder Talent Board</span><h1>Who can help me ship this?</h1><p>Find high-velocity builders for launch sprints, founding-engineer work, and focused product pushes.</p></div>
      <div class="talent-controls" aria-label="Talent filters">
        <button class="active" type="button" data-filter="all">All</button>
        <button type="button" data-filter="available">Available</button>
        <button type="button" data-filter="launch">Launch sprint</button>
        <button type="button" data-filter="mobile">Mobile</button>
        <button type="button" data-filter="saas">SaaS</button>
      </div>
      <div class="talent-grid" data-talent-output></div>
    </section>
  `;
}

function renderDashboard() {
  return `
    <section class="app-page dashboard-page">
      <div class="page-heading"><span>Receipt Command Center</span><h1>Turn this week's work into proof.</h1><p>Your GitHub imports, share-ready receipts, and public profile preview in one place.</p></div>
      <div class="dashboard-grid">
        <article class="featured-receipt"><span>Ready to share</span><h2>${sample.release.title}</h2><p>${sample.release.summary}</p><a class="primary-action" href="#/receipt">Preview receipt</a></article>
        <article class="next-action"><span>Next best action</span><h2>Annotate release context</h2><p>Add concise factual context, redact sensitive details, then generate share cards.</p><a class="secondary-action" href="#/studio">Open Receipt Studio</a></article>
      </div>
      ${statGrid([{ label: "PRs merged", value: "42" }, { label: "Releases made", value: "4" }, { label: "Repos selected", value: "6" }, { label: "Profile ready", value: "86%" }])}
      <div class="card-grid three">
        ${proofCard("Public profile preview", "See what founders and operators see when they inspect your proof.", "profile")}
        ${proofCard("Proof sources", "Choose which repos count toward your public receipts.", "repos")}
        ${proofCard("Weekly recap", "Generate a shareable proof card from this week's shipped work.", "studio")}
      </div>
    </section>
  `;
}

function renderRepos() {
  return `
    <section class="app-page">
      <div class="page-heading"><span>Proof Sources</span><h1>Choose which repos count.</h1><p>Keep setup simple: include useful proof sources and exclude noisy work.</p></div>
      <div class="repo-layout">
        <aside class="source-panel"><h2>6 repos included</h2><p>Private repo names can be hidden while verified activity still counts.</p><a class="primary-action" href="#/profile">Preview profile</a></aside>
        <div class="repo-list">${sample.repos.map((repo) => `<article class="repo-row"><div><strong>${repo.name}</strong><span>${repo.visibility} · ${repo.activity} · ${repo.release}</span></div><button type="button" class="${repo.included ? "active" : ""}" data-repo-toggle>${repo.included ? "Included" : "Excluded"}</button></article>`).join("")}</div>
      </div>
    </section>
  `;
}

function renderStudio() {
  return `
    <section class="app-page">
      <div class="page-heading"><span>Receipt Studio</span><h1>Edit the evidence. Generate the card.</h1><p>Start with imported GitHub facts, add context, redact sensitive details, and publish a factual receipt.</p></div>
      <div class="studio-layout">
        <article class="evidence-panel"><h2>Imported evidence</h2><p>${sample.release.repo} · ${sample.release.tag}</p>${sample.release.prs.map((pr) => `<p>#${pr.number} ${pr.title}</p>`).join("")}</article>
        <article class="editor-panel"><h2>Receipt editor</h2><label>Public context<textarea>Shipped release imports, project momentum filters, and share-card export polish.</textarea></label><label><input type="checkbox" checked> Hide private repo names</label><a class="primary-action" href="#/receipt">Publish receipt preview</a></article>
        <article class="share-output"><h2>Share card output</h2><p>${sample.release.title}</p><p>${sample.release.summary}</p><button type="button" data-copy-link>Copy receipt link</button></article>
      </div>
    </section>
  `;
}

function renderTrust() {
  return `
    <section class="app-page">
      <div class="page-heading"><span>Trust Center</span><h1>Clear rules for GitHub proof.</h1><p>Data access, scoring, privacy, and anti-gaming are part of the product, not fine print.</p></div>
      <div class="trust-grid">
        <article><h2>What PRBar reads</h2><p>Release metadata, PR metadata, repo metadata, contributor metadata, and selected public signals.</p></article>
        <article><h2>What counts</h2><p>Merged PRs, releases, projects, cadence, consistency, and verified GitHub source links.</p></article>
        <article><h2>What stays protected</h2><p>Private repo names, excluded repos, sensitive details, and organization-safe controls.</p></article>
        <article><h2>What does not count</h2><p>Token usage, vague claims, and unverified activity.</p></article>
        <article><h2>Anti-gaming</h2><p>Source links, transparent rules, weighting, anomaly review, and evidence-first receipts.</p></article>
      </div>
    </section>
  `;
}
```

- [ ] **Step 2: Verify page phrases exist**

Run:

```bash
rg "Receipt Command Center|Choose which repos count|Edit the evidence|Clear rules for GitHub proof|Who can help me ship this" mockups/web/app.js
```

Expected: all five phrases are present.

- [ ] **Step 3: Commit**

```bash
git add mockups/web/app.js
git commit -m "Add builder workspace and trust prototype pages"
```

---

### Task 5: Wire Interactions After Each Render

**Files:**
- Modify: `mockups/web/app.js`

- [ ] **Step 1: Add board, talent, repo, and copy-link helpers**

Add these functions before `render()`:

```javascript
function renderBoardRows(boardId = "rising") {
  const output = document.querySelector("[data-board-output]");
  if (!output) return;
  output.innerHTML = sample.boards[boardId]
    .map((row) => `<article class="leader-row"><strong>#${row.rank}</strong><div><strong>${row.name}</strong><span>${row.proof}</span></div><span>${row.momentum}</span></article>`)
    .join("");
}

function renderTalentRows(filter = "all") {
  const output = document.querySelector("[data-talent-output]");
  if (!output) return;
  const rows = filter === "all" ? sample.talent : sample.talent.filter((person) => person.tags.includes(filter));
  output.innerHTML = rows
    .map((person) => `<article class="talent-card"><h3>${person.handle}</h3><p>${person.fit}</p><strong>${person.proof}</strong>${tags(person.tags)}<a class="card-link" href="#/profile">Inspect receipts</a></article>`)
    .join("");
}

function bindPageInteractions() {
  document.querySelectorAll("[data-board]").forEach((button) => {
    button.addEventListener("click", () => {
      document.querySelectorAll("[data-board]").forEach((item) => item.classList.remove("active"));
      button.classList.add("active");
      renderBoardRows(button.dataset.board);
    });
  });

  document.querySelectorAll("[data-filter]").forEach((button) => {
    button.addEventListener("click", () => {
      document.querySelectorAll("[data-filter]").forEach((item) => item.classList.remove("active"));
      button.classList.add("active");
      renderTalentRows(button.dataset.filter);
    });
  });

  document.querySelectorAll("[data-repo-toggle]").forEach((button) => {
    button.addEventListener("click", () => {
      button.classList.toggle("active");
      button.textContent = button.classList.contains("active") ? "Included" : "Excluded";
    });
  });

  document.querySelectorAll("[data-copy-link]").forEach((button) => {
    button.addEventListener("click", () => {
      button.textContent = "Receipt link copied";
    });
  });

  renderBoardRows("rising");
  renderTalentRows("all");
}
```

- [ ] **Step 2: Call interaction binder from `render()`**

Replace the current `render()` function with:

```javascript
function render() {
  const routeId = routeIdFromHash();
  document.body.dataset.route = routeId;
  nav.innerHTML = routes.map((route) => `<a href="${route.path}" data-route-link="${route.id}">${route.label}</a>`).join("");
  document.querySelectorAll("[data-route-link]").forEach((link) => {
    link.classList.toggle("active", link.dataset.routeLink === routeId);
  });
  app.innerHTML = renderRoute(routeId);
  app.focus({ preventScroll: true });
  bindPageInteractions();
}
```

- [ ] **Step 3: Verify expected handlers are present**

Run:

```bash
rg "bindPageInteractions|renderBoardRows|renderTalentRows|data-repo-toggle|Receipt link copied" mockups/web/app.js
```

Expected: all five patterns are present.

- [ ] **Step 4: Commit**

```bash
git add mockups/web/app.js
git commit -m "Wire prototype routing interactions"
```

---

### Task 6: Add Responsive Styles For Expanded Prototype

**Files:**
- Modify: `mockups/web/styles.css`

- [ ] **Step 1: Append route layout styles**

Append these styles to `mockups/web/styles.css`:

```css
.app-page {
  padding: 112px clamp(20px, 5vw, 72px) 72px;
}

.app-hero {
  min-height: calc(100vh - 72px);
  display: grid;
  grid-template-columns: minmax(0, 1.1fr) minmax(280px, 0.9fr);
  gap: 32px;
  align-items: center;
}

.page-heading {
  max-width: 860px;
  margin-bottom: 28px;
}

.page-heading span,
.eyebrow {
  color: var(--accent);
  font-size: 0.78rem;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 0;
}

.page-heading h1,
.app-page h1 {
  margin: 8px 0 12px;
  font-size: clamp(2.4rem, 7vw, 5.8rem);
  line-height: 0.95;
}

.card-grid {
  display: grid;
  gap: 18px;
}

.card-grid.two {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.card-grid.three {
  grid-template-columns: repeat(3, minmax(0, 1fr));
}

.proof-card,
.feed-card,
.source-panel,
.profile-side,
.receipt-proof,
.table-card,
.traction-panel,
.featured-receipt,
.next-action,
.evidence-panel,
.editor-panel,
.share-output,
.trust-grid article {
  border: 1px solid var(--line);
  border-radius: 8px;
  background: var(--surface);
  padding: 20px;
  box-shadow: var(--shadow-soft);
}

.card-link,
.text-link {
  color: var(--accent);
  font-weight: 800;
  text-decoration: none;
}

.receipt-hero-card,
.featured-receipt {
  border-radius: 8px;
  padding: 28px;
  background: var(--ink);
  color: var(--paper);
}

.feed-layout,
.profile-shell,
.receipt-layout,
.project-layout,
.repo-layout,
.dashboard-grid,
.studio-layout {
  display: grid;
  grid-template-columns: minmax(0, 1.15fr) minmax(280px, 0.85fr);
  gap: 22px;
}

.feed-list,
.timeline,
.repo-list {
  display: grid;
  gap: 14px;
}

.profile-main,
.receipt-main {
  min-width: 0;
}

.tag-row,
.modal-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.tag-row span {
  border: 1px solid var(--line);
  border-radius: 999px;
  padding: 6px 10px;
  background: var(--paper);
  color: var(--muted);
  font-size: 0.82rem;
  font-weight: 700;
}

.receipt-notes {
  display: grid;
  gap: 10px;
  margin-top: 18px;
}

.pr-row,
.repo-row,
.leader-row {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) auto auto;
  gap: 14px;
  align-items: center;
  border-top: 1px solid var(--line);
  padding: 14px 0;
}

.repo-row button,
.share-output button {
  border: 1px solid var(--line);
  border-radius: 999px;
  background: var(--paper);
  padding: 8px 12px;
  font-weight: 800;
}

.repo-row button.active {
  background: var(--accent);
  color: var(--paper);
  border-color: var(--accent);
}

.studio-layout,
.trust-grid {
  grid-template-columns: repeat(3, minmax(0, 1fr));
}

.editor-panel textarea {
  width: 100%;
  min-height: 120px;
  margin: 10px 0 14px;
  border: 1px solid var(--line);
  border-radius: 8px;
  padding: 12px;
  font: inherit;
}

.modal-backdrop {
  position: fixed;
  inset: 0;
  z-index: 20;
  display: grid;
  place-items: center;
  padding: 20px;
  background: rgba(13, 18, 32, 0.42);
}

.modal-backdrop[hidden] {
  display: none;
}

.modal-panel {
  position: relative;
  width: min(560px, 100%);
  border-radius: 8px;
  background: var(--paper);
  padding: 28px;
  box-shadow: var(--shadow-strong);
}

.modal-close {
  position: absolute;
  top: 14px;
  right: 14px;
}

@media (max-width: 860px) {
  .app-page {
    padding: 96px 18px 56px;
  }

  .app-hero,
  .feed-layout,
  .profile-shell,
  .receipt-layout,
  .project-layout,
  .repo-layout,
  .dashboard-grid,
  .studio-layout,
  .trust-grid,
  .card-grid.two,
  .card-grid.three {
    grid-template-columns: 1fr;
  }

  .pr-row,
  .repo-row,
  .leader-row {
    grid-template-columns: 1fr;
  }
}
```

- [ ] **Step 2: Verify no negative letter spacing was introduced**

Run:

```bash
rg "letter-spacing:\\s*-" mockups/web/styles.css
```

Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add mockups/web/styles.css
git commit -m "Style expanded PRBar web prototype views"
```

---

### Task 7: Add Browser Smoke Test

**Files:**
- Create: `mockups/web/smoke-test.js`

- [ ] **Step 1: Create smoke test**

Create `mockups/web/smoke-test.js`:

```javascript
const { chromium } = require("/Users/neonwatty/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright");

const routes = [
  ["#/home", "Show the world your receipts."],
  ["#/network", "People and projects first."],
  ["#/profile", "Receipts beat resumes."],
  ["#/receipt", "SideProject Radar v2.1"],
  ["#/project", "SideProject Radar operating history."],
  ["#/boards", "Momentum Boards"],
  ["#/talent", "Who can help me ship this?"],
  ["#/dashboard", "Receipt Command Center"],
  ["#/repos", "Choose which repos count."],
  ["#/studio", "Edit the evidence."],
  ["#/trust", "Clear rules for GitHub proof."],
];

(async () => {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });

  for (const [hash, expected] of routes) {
    await page.goto(`http://127.0.0.1:4181/${hash}`, { waitUntil: "networkidle" });
    const body = await page.locator("body").innerText();
    if (!body.includes(expected)) {
      throw new Error(`Missing expected text for ${hash}: ${expected}`);
    }
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth);
    if (overflow) {
      throw new Error(`Horizontal overflow detected on ${hash}`);
    }
  }

  await page.goto("http://127.0.0.1:4181/#/boards", { waitUntil: "networkidle" });
  await page.locator("[data-board='projects']").click();
  if (!(await page.locator("body").innerText()).includes("Active projects")) {
    throw new Error("Boards interaction did not switch to projects");
  }

  await page.goto("http://127.0.0.1:4181/#/talent", { waitUntil: "networkidle" });
  await page.locator("[data-filter='available']").click();
  if (!(await page.locator("body").innerText()).includes("@nora.ship")) {
    throw new Error("Talent filter did not show available builders");
  }

  await browser.close();
  console.log("PRBar web prototype smoke test passed");
})();
```

- [ ] **Step 2: Run smoke test**

With the local server still running on port `4181`, run:

```bash
/Users/neonwatty/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node mockups/web/smoke-test.js
```

Expected:

```text
PRBar web prototype smoke test passed
```

- [ ] **Step 3: Commit**

```bash
git add mockups/web/smoke-test.js
git commit -m "Add PRBar web prototype smoke test"
```

---

### Task 8: Update README And Final Verification

**Files:**
- Modify: `mockups/web/README.md`

- [ ] **Step 1: Replace README content**

Replace `mockups/web/README.md` with:

````markdown
# PRBar Web Prototype

Static expanded product prototype for PRBar, deployed through GitHub Pages at `/web/`.

Run locally:

```bash
python3 -m http.server 4181 --directory mockups/web
```

Visit:

```text
http://127.0.0.1:4181/#/home
```

Smoke test:

```bash
/Users/neonwatty/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node mockups/web/smoke-test.js
```

The prototype includes:

- Home / Product Story
- Proof Network
- Builder Profile
- Release Receipt
- Project Page
- Momentum Boards
- Talent Board
- Private Dashboard / Receipt Command Center
- Repo Picker / Proof Sources
- Receipt Studio
- Trust Center
````

- [ ] **Step 2: Run final local verification**

Run:

```bash
python3 -m http.server 4181 --directory mockups/web
```

In another terminal:

```bash
/Users/neonwatty/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node mockups/web/smoke-test.js
```

Expected:

```text
PRBar web prototype smoke test passed
```

- [ ] **Step 3: Check changed files**

Run:

```bash
git status --short
git diff --stat origin/main...HEAD
```

Expected changed files:

```text
Docs/superpowers/specs/2026-05-27-prbar-web-expanded-prototype-design.md
Docs/superpowers/plans/2026-05-27-prbar-web-expanded-prototype.md
mockups/web/README.md
mockups/web/app.js
mockups/web/index.html
mockups/web/smoke-test.js
mockups/web/styles.css
```

- [ ] **Step 4: Commit README**

```bash
git add mockups/web/README.md
git commit -m "Document expanded PRBar web prototype"
```

---

### Task 9: Prepare PR And GitHub Pages Verification

**Files:**
- No code changes.

- [ ] **Step 1: Push branch**

```bash
git push -u origin codex/web-expanded-prototype-spec
```

Expected: branch is pushed to `origin`.

- [ ] **Step 2: Open PR**

```bash
gh pr create --base main --head codex/web-expanded-prototype-spec --title "Expand PRBar web prototype pages" --body "## Summary
- Expand the PRBar web mockup into a routed static prototype
- Add Home, Proof Network, Builder Profile, Release Receipt, Project Page, Momentum Boards, Talent Board, Dashboard, Repo Picker, Receipt Studio, and Trust Center views
- Add a browser smoke test for routes, interactions, and mobile overflow

## Verification
- python3 -m http.server 4181 --directory mockups/web
- /Users/neonwatty/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node mockups/web/smoke-test.js"
```

- [ ] **Step 3: Enable auto-merge**

```bash
gh pr merge --auto --squash
```

Expected: auto-merge is enabled or the PR enters the merge queue.

- [ ] **Step 4: After merge, verify Pages**

Run:

```bash
gh run list --workflow pages.yml --limit 5 --json databaseId,status,conclusion,headBranch,displayTitle,createdAt,url
curl -sL --max-time 20 https://mean-weasel.github.io/prbar/web/ | rg "Show the world your receipts|Receipts beat resumes"
```

Expected: latest Pages run succeeds and the public URL contains both phrases.
