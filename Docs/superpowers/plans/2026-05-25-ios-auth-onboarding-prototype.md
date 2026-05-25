# iOS Auth Onboarding Prototype Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand the PRBar iOS HTML prototype from an authenticated happy path into a complete first-run GitHub app prototype with sign-in, permissions, repo setup, privacy defaults, sync/error states, and a more native iOS interaction model.

**Architecture:** Keep the prototype as static HTML/CSS/vanilla JS in `mockups/ios`, but introduce an explicit app state machine: signed out, permission rationale, connecting, repo setup, privacy setup, syncing, authenticated, and recoverable error states. Add review query parameters so each state can be deep-linked and screenshot-tested without real GitHub calls.

**Tech Stack:** Static HTML, CSS, vanilla JavaScript, existing `npm run verify:ios-mockups` marker verification, Playwright CLI screenshots for visual checks.

---

## File Structure

- Modify `mockups/ios/app.js`
  - Owns fixture data, app state, route parsing, render functions, click handlers, onboarding screens, dashboard screens, and fake GitHub state transitions.
- Modify `mockups/ios/styles.css`
  - Owns native-iOS-inspired styling, onboarding layouts, grouped lists, tab bar polish, bottom sheets, banners, and status/empty/error states.
- Modify `mockups/ios/index.html`
  - Updates review copy to include first-run/auth/onboarding coverage.
- Modify `mockups/ios/README.md`
  - Documents prototype states, query links, and review coverage.
- Modify `scripts/verify-ios-mockups.mjs`
  - Adds required markers for auth, onboarding, privacy, sync, error, and iOS polish.

No production macOS app files should be touched in this pass.

## Desired Prototype Flow

1. Welcome screen: PRBar value, `Sign in with GitHub`, `Try Demo`.
2. Permission rationale: explain read-only GitHub access and private repo implications.
3. Connecting screen: fake OAuth/device flow status.
4. Repo setup: searchable grouped repo picker with public/private badges, select all/none, and an SSO-blocked example.
5. Privacy defaults: card sharing defaults and private-detail warning.
6. Sync screen: staged loading for account, organizations, repos, PRs, releases.
7. Authenticated app: existing Today / Activity / Releases / Cards / More flow, with improved native-iOS styling.
8. Recoverable states: expired token, rate limit, partial sync, no repos, no activity, no releases, private export warning.

---

### Task 1: Add Verification Markers For The New Flow

**Files:**
- Modify: `scripts/verify-ios-mockups.mjs`
- Modify: `mockups/ios/README.md`
- Modify: `mockups/ios/index.html`

- [ ] **Step 1: Extend verifier requirements before implementation**

In `scripts/verify-ios-mockups.mjs`, add these markers to the existing arrays.

```js
const requiredHtml = [
  "data-prototype-app",
  "Interactive mobile app",
  "bottom nav",
  "More menu",
  "GitHub Releases",
  "Repo inclusion",
  "Cards from activity or GitHub Releases",
  "GitHub sign-in",
  "First-run onboarding"
];

const requiredCss = [
  ".bottom-nav",
  ".app-content",
  ".share-card.terminal",
  ".share-card.launch",
  ".share-card.hype",
  ".share-card.minimal",
  ".sheet-backdrop",
  ".bottom-sheet",
  ".card-back",
  ".evidence-list",
  ".card-actions",
  ".menu-list",
  ".repo-list",
  ".auth-screen",
  ".ios-list",
  ".status-banner",
  ".native-tabbar",
  ".permission-list",
  ".sync-steps"
];

const requiredJs = [
  "const repositories",
  "const pullRequests",
  "const releases",
  "activeTab",
  "activeMoreScreen",
  "activeSheet",
  "cardSide",
  "authState",
  "onboardingStep",
  "syncState",
  "applyInitialRoute",
  "renderWelcome",
  "renderPermissionRationale",
  "renderConnecting",
  "renderRepoSetup",
  "renderPrivacySetup",
  "renderSyncing",
  "renderAuthIssue",
  "renderEmptyState",
  "renderToday",
  "renderActivity",
  "renderReleases",
  "renderCards",
  "renderCardBackEvidence",
  "renderEditSheet",
  "renderShareSheet",
  "renderMore",
  "renderRepos",
  "Sign in with GitHub",
  "Continue to GitHub",
  "Choose repositories",
  "Private details warning",
  "Authorize SSO",
  "Reconnect GitHub",
  "Rate limit",
  "Last synced",
  "Make Release Card",
  "Open on GitHub",
  "Copy release notes",
  "Edit Card",
  "Share Card",
  "Share Front",
  "Share Back",
  "Share Both",
  "Copy Caption",
  "Included repos power Activity, Releases, and Cards.",
  "day",
  "week",
  "month"
];

const requiredReadme = [
  "Interactive HTML prototype",
  "Today / Activity / Releases / Cards / More",
  "First-run GitHub sign-in",
  "Permission rationale",
  "Repo setup",
  "Privacy defaults",
  "Sync and recovery states",
  "More menu with Repos, Settings, Privacy, Sample Data, and About",
  "fixture-backed",
  "Front/back card flip",
  "Share sheet"
];
```

- [ ] **Step 2: Run verifier to confirm it fails**

Run:

```bash
npm run verify:ios-mockups
```

Expected: failure mentioning `GitHub sign-in` or another newly added marker.

- [ ] **Step 3: Update static review copy**

In `mockups/ios/index.html`, update the intro paragraph and review list.

```html
<p>Use the phone below like an app: sign in with GitHub, set repo and privacy defaults, switch ranges, browse GitHub Releases, create cards, and open More for secondary settings.</p>
```

Add these list items to the coverage list:

```html
<li>GitHub sign-in and first-run onboarding</li>
<li>Permission rationale before OAuth</li>
<li>Repo setup, privacy defaults, and sync states</li>
<li>Recovery states for reconnect, rate limits, private sharing, and empty data</li>
```

- [ ] **Step 4: Update README coverage**

Add these bullets to `mockups/ios/README.md`:

```markdown
- First-run GitHub sign-in and demo mode
- Permission rationale before OAuth
- Repo setup with public/private visibility and SSO-blocked examples
- Privacy defaults before sharing
- Sync and recovery states for connecting, stale data, reconnect, rate limits, no repos, no PRs, and no releases
```

Add review links:

```markdown
Additional review links:

- `?auth=signed-out`
- `?auth=permissions`
- `?auth=connecting`
- `?auth=repo-setup`
- `?auth=privacy`
- `?auth=syncing`
- `?auth=expired`
- `?auth=rate-limit`
- `?empty=no-repos`
- `?empty=no-activity`
- `?tab=cards&private-warning=true`
```

- [ ] **Step 5: Commit verifier/docs scaffold**

Run:

```bash
git add scripts/verify-ios-mockups.mjs mockups/ios/index.html mockups/ios/README.md
git commit -m "Plan iOS auth onboarding prototype coverage"
```

---

### Task 2: Add App State Machine And Review Routing

**Files:**
- Modify: `mockups/ios/app.js`
- Test: `scripts/verify-ios-mockups.mjs`

- [ ] **Step 1: Add auth/onboarding state**

In `mockups/ios/app.js`, expand `state` with these fields.

```js
const state = {
  authState: "authenticated",
  onboardingStep: "done",
  syncState: "fresh",
  authIssue: null,
  emptyState: null,
  activeTab: "today",
  activeMoreScreen: null,
  activeSheet: null,
  range: "week",
  selectedReleaseId: "rel-prbar-140",
  repoSearch: "",
  toast: "",
  cardSide: "front",
  privateShareWarning: false,
  cardDraft: {
    sourceType: "activity",
    sourceId: null,
    theme: "clean",
    showRepos: true,
    showHandle: true,
    exactCounts: true,
    showPrivateLabels: false
  }
};
```

- [ ] **Step 2: Add route parser support**

Replace `applyInitialRoute()` with:

```js
function applyInitialRoute() {
  const params = new URLSearchParams(window.location.search);
  const auth = params.get("auth");
  const empty = params.get("empty");
  const tab = params.get("tab");
  const side = params.get("side");
  const sheet = params.get("sheet");
  const privateWarning = params.get("private-warning");

  const authRoutes = {
    "signed-out": ["signedOut", "welcome", "fresh", null],
    permissions: ["onboarding", "permissions", "fresh", null],
    connecting: ["onboarding", "connecting", "connecting", null],
    "repo-setup": ["onboarding", "repos", "fresh", null],
    privacy: ["onboarding", "privacy", "fresh", null],
    syncing: ["onboarding", "syncing", "syncing", null],
    expired: ["issue", "done", "stale", "expired"],
    "rate-limit": ["issue", "done", "rateLimited", "rateLimit"]
  };

  if (authRoutes[auth]) {
    const [authState, onboardingStep, syncState, authIssue] = authRoutes[auth];
    state.authState = authState;
    state.onboardingStep = onboardingStep;
    state.syncState = syncState;
    state.authIssue = authIssue;
  }

  if (empty === "no-repos" || empty === "no-activity" || empty === "no-releases") {
    state.emptyState = empty;
    state.authState = "authenticated";
    state.onboardingStep = "done";
  }

  if (navItems.some(([id]) => id === tab)) state.activeTab = tab;
  if (side === "back") state.cardSide = "back";
  if (sheet === "edit" || sheet === "share") state.activeSheet = sheet;
  if (privateWarning === "true") {
    state.activeTab = "cards";
    state.privateShareWarning = true;
  }
}
```

- [ ] **Step 3: Route render through auth state**

At the top of `renderActiveScreen()`, add:

```js
function renderActiveScreen() {
  if (state.authState === "signedOut") return renderWelcome();
  if (state.authState === "onboarding") return renderOnboarding();
  if (state.authState === "issue") return renderAuthIssue();
  if (state.emptyState) return renderEmptyState();
  if (state.activeTab === "today") return renderToday();
  if (state.activeTab === "activity") return renderActivity();
  if (state.activeTab === "releases") return renderReleases();
  if (state.activeTab === "cards") return renderCards();
  return renderMore();
}
```

- [ ] **Step 4: Hide tab bar during onboarding**

In `render()`, change bottom nav rendering:

```js
${state.authState === "authenticated" || state.authState === "issue" ? renderBottomNav() : ""}
```

- [ ] **Step 5: Add event transitions**

Add handlers in the click listener:

```js
if (action === "start-github") {
  state.authState = "onboarding";
  state.onboardingStep = "permissions";
  render();
}
if (action === "try-demo") {
  state.authState = "authenticated";
  state.onboardingStep = "done";
  toast("Demo data loaded");
}
if (action === "continue-github") {
  state.onboardingStep = "connecting";
  state.syncState = "connecting";
  render();
}
if (action === "oauth-success") {
  state.onboardingStep = "repos";
  state.syncState = "fresh";
  render();
}
if (action === "continue-repos") {
  state.onboardingStep = "privacy";
  render();
}
if (action === "continue-privacy") {
  state.onboardingStep = "syncing";
  state.syncState = "syncing";
  render();
}
if (action === "finish-sync") {
  state.authState = "authenticated";
  state.onboardingStep = "done";
  state.syncState = "fresh";
  state.activeTab = "today";
  render();
}
if (action === "reconnect-github") {
  state.authState = "onboarding";
  state.onboardingStep = "permissions";
  state.authIssue = null;
  render();
}
```

- [ ] **Step 6: Verify syntax**

Run:

```bash
node --check mockups/ios/app.js
```

Expected: no output and exit code 0.

- [ ] **Step 7: Commit state machine**

Run:

```bash
git add mockups/ios/app.js
git commit -m "Add iOS prototype auth state machine"
```

---

### Task 3: Build Welcome, Permission, Connecting, And Sync Screens

**Files:**
- Modify: `mockups/ios/app.js`
- Modify: `mockups/ios/styles.css`

- [ ] **Step 1: Add onboarding dispatcher**

Add below `renderActiveScreen()`:

```js
function renderOnboarding() {
  if (state.onboardingStep === "permissions") return renderPermissionRationale();
  if (state.onboardingStep === "connecting") return renderConnecting();
  if (state.onboardingStep === "repos") return renderRepoSetup();
  if (state.onboardingStep === "privacy") return renderPrivacySetup();
  if (state.onboardingStep === "syncing") return renderSyncing();
  return renderWelcome();
}
```

- [ ] **Step 2: Add welcome screen**

Add:

```js
function renderWelcome() {
  return `
    <section class="auth-screen">
      <div class="auth-hero">
        <p class="microcopy">PRBar for iOS</p>
        <h1>Carry your shipping rhythm with you.</h1>
        <p>Connect GitHub to see merged PRs, releases, and shareable proof-of-work cards from your selected repositories.</p>
      </div>
      <section class="permission-list">
        <p><strong>Read-only GitHub data</strong><span>PRs, repositories, releases, and account identity.</span></p>
        <p><strong>Private by default</strong><span>You choose which repos appear and what card details are exported.</span></p>
        <p><strong>No write access</strong><span>The app does not create PRs, tags, releases, or comments.</span></p>
      </section>
      <button class="primary-action" type="button" data-action="start-github">Sign in with GitHub</button>
      <button class="secondary-action" type="button" data-action="try-demo">Try Demo</button>
    </section>
  `;
}
```

- [ ] **Step 3: Add permission rationale screen**

Add:

```js
function renderPermissionRationale() {
  return `
    <section class="auth-screen">
      <button class="back-button" type="button" data-action="auth-back" data-step="welcome">Back</button>
      <div class="auth-hero">
        <p class="microcopy">GitHub permissions</p>
        <h1>Choose exactly what PRBar can read.</h1>
        <p>PRBar uses read-only access to calculate your activity and find releases. Private repo names and release notes stay hidden from shared cards unless you opt in.</p>
      </div>
      <section class="ios-list">
        <p><span>Account identity</span><strong>Required</strong></p>
        <p><span>Repository metadata</span><strong>Required</strong></p>
        <p><span>Pull requests and releases</span><strong>Required</strong></p>
        <p><span>Private repositories</span><strong>Optional</strong></p>
      </section>
      <button class="primary-action" type="button" data-action="continue-github">Continue to GitHub</button>
    </section>
  `;
}
```

Add handler:

```js
if (action === "auth-back") {
  state.onboardingStep = target.dataset.step;
  state.authState = target.dataset.step === "welcome" ? "signedOut" : "onboarding";
  render();
}
```

- [ ] **Step 4: Add connecting screen**

Add:

```js
function renderConnecting() {
  return `
    <section class="auth-screen">
      <div class="auth-hero">
        <p class="microcopy">Connecting</p>
        <h1>Waiting for GitHub.</h1>
        <p>This prototype simulates the OAuth return step. Production should handle cancel, denied scopes, expired device code, and network failure here.</p>
      </div>
      <section class="sync-steps">
        <p class="is-complete"><span></span>Opened GitHub authorization</p>
        <p class="is-active"><span></span>Waiting for account approval</p>
        <p><span></span>Preparing repository setup</p>
      </section>
      <button class="primary-action" type="button" data-action="oauth-success">Simulate GitHub Success</button>
      <button class="secondary-action" type="button" data-action="auth-cancel">Cancel</button>
    </section>
  `;
}
```

Add handler:

```js
if (action === "auth-cancel") {
  state.authState = "signedOut";
  state.onboardingStep = "welcome";
  toast("GitHub sign-in cancelled");
}
```

- [ ] **Step 5: Add sync screen**

Add:

```js
function renderSyncing() {
  return `
    <section class="auth-screen">
      <div class="auth-hero">
        <p class="microcopy">Initial sync</p>
        <h1>Building your first activity view.</h1>
        <p>PRBar is collecting selected repos, merged PRs, releases, and recent activity. Real sync should show partial progress and retry options.</p>
      </div>
      <section class="sync-steps">
        <p class="is-complete"><span></span>Account loaded</p>
        <p class="is-complete"><span></span>Repositories selected</p>
        <p class="is-active"><span></span>Pull requests and releases syncing</p>
        <p><span></span>Cards ready</p>
      </section>
      <button class="primary-action" type="button" data-action="finish-sync">View PRBar</button>
    </section>
  `;
}
```

- [ ] **Step 6: Add base auth styles**

Add to `mockups/ios/styles.css`:

```css
.auth-screen {
  min-height: 100%;
  display: grid;
  align-content: center;
  gap: 14px;
  padding: 10px 0 24px;
}

.auth-hero {
  display: grid;
  gap: 10px;
}

.auth-hero h1 {
  margin: 0;
  font-size: 34px;
  line-height: 1.02;
  font-weight: 820;
}

.auth-hero p:last-child {
  margin: 0;
  color: var(--muted);
  line-height: 1.45;
}

.permission-list,
.ios-list,
.sync-steps {
  display: grid;
  gap: 0;
  border: 1px solid var(--line);
  border-radius: 12px;
  background: #fff;
  overflow: hidden;
}

.permission-list p,
.ios-list p,
.sync-steps p {
  margin: 0;
  padding: 13px 14px;
  border-top: 1px solid var(--line);
}

.permission-list p:first-child,
.ios-list p:first-child,
.sync-steps p:first-child {
  border-top: 0;
}

.permission-list span {
  display: block;
  margin-top: 4px;
  color: var(--muted);
  font-size: 12px;
  line-height: 1.35;
}

.ios-list p {
  display: flex;
  justify-content: space-between;
  gap: 12px;
}

.sync-steps p {
  display: flex;
  align-items: center;
  gap: 10px;
  color: var(--muted);
}

.sync-steps p span {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  border: 2px solid var(--quiet);
}

.sync-steps p.is-complete span {
  border-color: var(--green);
  background: var(--green);
}

.sync-steps p.is-active span {
  border-color: var(--cyan);
  box-shadow: 0 0 0 5px rgba(14, 165, 233, 0.14);
}
```

- [ ] **Step 7: Verify and commit**

Run:

```bash
npm run verify:ios-mockups
node --check mockups/ios/app.js
```

Expected: verifier still fails if later markers are not implemented; syntax passes.

Commit:

```bash
git add mockups/ios/app.js mockups/ios/styles.css
git commit -m "Add GitHub sign-in onboarding screens"
```

---

### Task 4: Build First-Run Repo Setup

**Files:**
- Modify: `mockups/ios/app.js`
- Modify: `mockups/ios/styles.css`

- [ ] **Step 1: Expand repo fixtures**

Change `repositories` objects to include owner, reason, SSO, and last sync state.

```js
const repositories = [
  { id: "prbar", owner: "neonwatty", name: "prbar", visibility: "public", color: "#0ea5e9", included: true, recommended: true, access: "ready", reason: "Most active this week" },
  { id: "launch-kit", owner: "neonwatty", name: "launch-kit", visibility: "public", color: "#16a34a", included: true, recommended: true, access: "ready", reason: "Recent releases" },
  { id: "client-api", owner: "example", name: "client-api", visibility: "private", color: "#f59e0b", included: true, recommended: true, access: "ready", reason: "Private repo included" },
  { id: "docs-site", owner: "neonwatty", name: "docs-site", visibility: "public", color: "#7c3aed", included: false, recommended: false, access: "ready", reason: "Documentation releases" },
  { id: "ops-console", owner: "example", name: "ops-console", visibility: "private", color: "#ef4444", included: false, recommended: false, access: "sso", reason: "Needs SSO authorization" }
];
```

- [ ] **Step 2: Add repo setup renderer**

Add:

```js
function renderRepoSetup() {
  const filtered = filteredRepos();
  const selectedCount = includedRepos().length;
  return `
    <section class="screen stack">
      <section class="section-title">
        <div><p class="microcopy">Repository setup</p><h1>Choose repositories</h1></div>
      </section>
      <section class="status-banner">
        <strong>${selectedCount} selected</strong>
        <p>Included repos power Activity, Releases, and Cards. Private repos are hidden from cards unless you allow them.</p>
      </section>
      <input class="search-input" type="search" placeholder="Search repositories" value="${escapeHtml(state.repoSearch)}" data-action="repo-search">
      <section class="repo-list setup-repos">
        ${filtered.length ? filtered.map(renderRepoSetupRow).join("") : renderRepoSearchEmpty()}
      </section>
      <section class="card-actions">
        <button class="secondary-action" type="button" data-action="select-none">Select None</button>
        <button class="secondary-action" type="button" data-action="include-all">Include All</button>
      </section>
      <button class="primary-action" type="button" data-action="continue-repos" ${selectedCount ? "" : "disabled"}>Continue</button>
    </section>
  `;
}
```

- [ ] **Step 3: Add helper renderers**

Add:

```js
function filteredRepos() {
  const query = state.repoSearch.trim().toLowerCase();
  if (!query) return repositories;
  return repositories.filter((repo) => `${repo.owner}/${repo.name}`.toLowerCase().includes(query));
}

function renderRepoSetupRow(repo) {
  const blocked = repo.access === "sso";
  return `
    <label class="${blocked ? "is-blocked" : ""}">
      <input type="checkbox" ${repo.included ? "checked" : ""} ${blocked ? "disabled" : ""} data-action="toggle-repo" data-repo-id="${repo.id}">
      <i style="background:${repo.color}"></i>
      <span><strong>${escapeHtml(repo.owner)}/${escapeHtml(repo.name)}</strong><small>${escapeHtml(repo.reason)}</small></span>
      <em>${blocked ? "SSO" : repo.visibility}</em>
      ${blocked ? `<button class="small-button" type="button" data-action="authorize-sso">Authorize SSO</button>` : ""}
    </label>
  `;
}

function renderRepoSearchEmpty() {
  return `
    <section class="empty-state">
      <strong>No matching repositories</strong>
      <p>Check the owner or repo name, or make sure GitHub access includes the organization.</p>
    </section>
  `;
}
```

- [ ] **Step 4: Add repo setup handlers**

Add:

```js
if (action === "select-none") {
  repositories.forEach((repo) => {
    if (repo.access !== "sso") repo.included = false;
  });
  render();
}
if (action === "authorize-sso") toast("SSO authorization needed in GitHub");
```

- [ ] **Step 5: Style setup rows**

Add:

```css
.setup-repos label {
  grid-template-columns: auto auto 1fr auto;
}

.setup-repos small {
  display: block;
  margin-top: 3px;
  color: var(--muted);
  font-size: 11px;
}

.setup-repos label.is-blocked {
  opacity: 0.72;
  grid-template-columns: auto auto 1fr auto auto;
}

.primary-action:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}
```

- [ ] **Step 6: Verify and commit**

Run:

```bash
node --check mockups/ios/app.js
npm run verify:ios-mockups
```

Commit:

```bash
git add mockups/ios/app.js mockups/ios/styles.css
git commit -m "Add first-run repository setup"
```

---

### Task 5: Add Privacy Defaults And Private Share Warning

**Files:**
- Modify: `mockups/ios/app.js`
- Modify: `mockups/ios/styles.css`

- [ ] **Step 1: Add privacy setup screen**

Add:

```js
function renderPrivacySetup() {
  return `
    <section class="screen stack">
      <section class="section-title">
        <div><p class="microcopy">Privacy defaults</p><h1>Decide what leaves the app</h1></div>
      </section>
      <section class="status-banner warning">
        <strong>Private details warning</strong>
        <p>Private repo names, PR titles, release notes, exact counts, org names, and links can reveal work. PRBar should ask before exporting them.</p>
      </section>
      <section class="toggle-list">
        ${toggle("showRepos", "Show repo names on cards")}
        ${toggle("showHandle", "Show GitHub handle")}
        ${toggle("exactCounts", "Use exact counts")}
        ${toggle("showPrivateLabels", "Show private labels")}
      </section>
      <section class="ios-list">
        <p><span>Local cache</span><strong>Clearable</strong></p>
        <p><span>GitHub token</span><strong>Keychain</strong></p>
        <p><span>Analytics</span><strong>Off in prototype</strong></p>
      </section>
      <button class="primary-action" type="button" data-action="continue-privacy">Continue</button>
    </section>
  `;
}
```

- [ ] **Step 2: Show private warning before share**

In `renderCards()`, before `renderShareCard(source)`, add:

```js
${state.privateShareWarning ? renderPrivateShareWarning() : ""}
```

Add:

```js
function renderPrivateShareWarning() {
  return `
    <section class="status-banner warning">
      <strong>Private details warning</strong>
      <p>This card may include private repo names or release details. Review the back side and privacy settings before sharing.</p>
    </section>
  `;
}
```

In the `open-sheet` handler, add:

```js
if (target.dataset.sheet === "share" && includedRepos().some((repo) => repo.visibility === "private") && state.cardDraft.showRepos) {
  state.privateShareWarning = true;
}
```

- [ ] **Step 3: Style warnings**

Add:

```css
.status-banner {
  padding: 13px 14px;
  border: 1px solid #bae6fd;
  border-radius: 12px;
  background: #f0f9ff;
}

.status-banner.warning {
  border-color: #fed7aa;
  background: #fff7ed;
}

.status-banner p {
  margin: 5px 0 0;
  color: var(--muted);
  font-size: 12px;
  line-height: 1.4;
}
```

- [ ] **Step 4: Verify and commit**

Run:

```bash
node --check mockups/ios/app.js
npm run verify:ios-mockups
```

Commit:

```bash
git add mockups/ios/app.js mockups/ios/styles.css
git commit -m "Add privacy defaults and share warnings"
```

---

### Task 6: Add Recovery And Empty States

**Files:**
- Modify: `mockups/ios/app.js`
- Modify: `mockups/ios/styles.css`

- [ ] **Step 1: Add auth issue screen**

Add:

```js
function renderAuthIssue() {
  const issue = state.authIssue === "rateLimit"
    ? {
        title: "Rate limit reached",
        detail: "GitHub asked PRBar to slow down. Showing the last synced data until the retry window opens.",
        action: "Retry Sync",
        meta: "Rate limit"
      }
    : {
        title: "Reconnect GitHub",
        detail: "Your GitHub token expired or access was revoked. Reconnect to refresh PRs and releases.",
        action: "Reconnect GitHub",
        meta: "Authentication"
      };
  return `
    <section class="screen stack">
      <section class="status-banner warning">
        <strong>${issue.meta}</strong>
        <p>Last synced 18 minutes ago</p>
      </section>
      <section class="empty-state recovery-state">
        <strong>${issue.title}</strong>
        <p>${issue.detail}</p>
      </section>
      <button class="primary-action" type="button" data-action="reconnect-github">${issue.action}</button>
      <button class="secondary-action" type="button" data-action="use-cached-data">Use Cached Data</button>
    </section>
  `;
}
```

Add handler:

```js
if (action === "use-cached-data") {
  state.authState = "authenticated";
  state.authIssue = null;
  state.syncState = "stale";
  toast("Showing cached data");
}
```

- [ ] **Step 2: Add empty state screen**

Add:

```js
function renderEmptyState() {
  const states = {
    "no-repos": ["No repositories selected", "Choose at least one repo to populate PR stats, releases, and cards.", "Choose repositories"],
    "no-activity": ["No merged PRs yet", "Selected repos have no merged PRs in this range. Try Month or include more repos.", "Open Activity"],
    "no-releases": ["No GitHub releases found", "Selected repos may use tags without releases or have draft releases hidden.", "Open Releases"]
  };
  const [title, detail, actionLabel] = states[state.emptyState];
  return `
    <section class="screen stack">
      <section class="empty-state recovery-state">
        <strong>${title}</strong>
        <p>${detail}</p>
      </section>
      <button class="primary-action" type="button" data-action="resolve-empty">${actionLabel}</button>
    </section>
  `;
}
```

Add handler:

```js
if (action === "resolve-empty") {
  if (state.emptyState === "no-repos") {
    state.authState = "onboarding";
    state.onboardingStep = "repos";
  } else if (state.emptyState === "no-releases") {
    state.activeTab = "releases";
    state.emptyState = null;
  } else {
    state.activeTab = "activity";
    state.emptyState = null;
  }
  render();
}
```

- [ ] **Step 3: Add stale data banner to dashboard**

In `renderToday()`, add under the range control:

```js
${state.syncState === "stale" ? `<section class="status-banner"><strong>Last synced 18 minutes ago</strong><p>Showing cached GitHub activity. Pull to refresh in the native app.</p></section>` : ""}
```

- [ ] **Step 4: Verify and commit**

Run:

```bash
node --check mockups/ios/app.js
npm run verify:ios-mockups
```

Commit:

```bash
git add mockups/ios/app.js mockups/ios/styles.css
git commit -m "Add iOS prototype recovery states"
```

---

### Task 7: Polish Toward Native iOS Conventions

**Files:**
- Modify: `mockups/ios/app.js`
- Modify: `mockups/ios/styles.css`

- [ ] **Step 1: Change tab icons to SF-symbol-like labels**

Replace `navItems` with:

```js
const navItems = [
  ["today", "Today", "●"],
  ["activity", "Activity", "▥"],
  ["releases", "Releases", "◇"],
  ["cards", "Cards", "▣"],
  ["more", "More", "•••"]
];
```

Update `renderBottomNav()`:

```js
function renderBottomNav() {
  return `
    <nav class="bottom-nav native-tabbar" aria-label="bottom nav">
      ${navItems.map(([id, label, icon]) => `
        <button type="button" class="${state.activeTab === id ? "is-active" : ""}" data-action="nav" data-tab="${id}" aria-label="${label}" aria-current="${state.activeTab === id ? "page" : "false"}">
          <span>${icon}</span>
          ${label}
        </button>
      `).join("")}
    </nav>
  `;
}
```

Update title lookup in `renderHeader()`:

```js
: navItems.find(([id]) => id === state.activeTab)?.[1];
```

- [ ] **Step 2: Make header feel less web-dashboard-like**

Replace header markup with:

```js
function renderHeader() {
  const title = state.activeTab === "more" && state.activeMoreScreen
    ? moreItems.find(([id]) => id === state.activeMoreScreen)?.[1]
    : navItems.find(([id]) => id === state.activeTab)?.[1];
  const authenticated = state.authState === "authenticated" || state.authState === "issue";
  return `
    <header class="app-header native-header">
      <div>
        <p class="microcopy">${authenticated ? "Connected as @neonwatty" : "PRBar"}</p>
        <strong>${title || "Welcome"}</strong>
      </div>
      ${authenticated ? `<button class="screen-heading" type="button" data-action="open-more" data-screen="settings" aria-label="Account settings">@</button>` : ""}
    </header>
  `;
}
```

- [ ] **Step 3: Add sheet grabber**

In `renderActiveSheet()`, add:

```js
<div class="sheet-grabber" aria-hidden="true"></div>
```

immediately inside `.bottom-sheet`.

Add CSS:

```css
.sheet-grabber {
  justify-self: center;
  width: 38px;
  height: 5px;
  border-radius: 999px;
  background: #cbd5e1;
}
```

- [ ] **Step 4: Reduce selected tab pill styling**

Replace `.bottom-nav button.is-active` with:

```css
.native-tabbar button.is-active {
  background: transparent;
  color: var(--cyan);
}
```

- [ ] **Step 5: Verify visual screenshots**

Run a local server:

```bash
python3 -m http.server 4173
```

In another shell, capture:

```bash
npx --yes playwright@1.52.0 screenshot --full-page --viewport-size=390,844 'http://localhost:4173/mockups/ios/?auth=signed-out' /tmp/prbar-ios-auth-welcome.png
npx --yes playwright@1.52.0 screenshot --full-page --viewport-size=390,844 'http://localhost:4173/mockups/ios/?auth=repo-setup' /tmp/prbar-ios-repo-setup.png
npx --yes playwright@1.52.0 screenshot --full-page --viewport-size=390,844 'http://localhost:4173/mockups/ios/?tab=cards&private-warning=true' /tmp/prbar-ios-private-share-warning.png
```

Stop the server with `Ctrl-C`.

Expected: no text overlap, no clipped primary actions, bottom nav appears only in authenticated states, onboarding screens read as standalone iOS app screens.

- [ ] **Step 6: Verify and commit**

Run:

```bash
node --check mockups/ios/app.js
npm run verify:ios-mockups
```

Commit:

```bash
git add mockups/ios/app.js mockups/ios/styles.css
git commit -m "Polish iOS prototype native interaction patterns"
```

---

### Task 8: Final Documentation And Review Pass

**Files:**
- Modify: `mockups/ios/README.md`
- Modify: `Docs/superpowers/specs/2026-05-25-ios-interactive-prototype-design.md`
- Modify: `Docs/superpowers/plans/2026-05-25-ios-interactive-prototype.md`

- [ ] **Step 1: Update README with final state table**

Add:

```markdown
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
| Private share warning | `?tab=cards&private-warning=true` |
```

- [ ] **Step 2: Add implementation notes to the design spec**

Add a section:

```markdown
## Auth And GitHub Integration Decisions

- Model auth as a state machine: signed out, permission rationale, connecting, repo setup, privacy setup, syncing, authenticated, and recoverable issue.
- Prefer GitHub App OAuth with least-privilege access and explicit private-repo opt-in.
- Store tokens in Keychain in the native app.
- Cache derived stats separately from raw private repo text where possible.
- Treat private repo names, PR titles, release notes, exact counts, org names, and links as share-sensitive.
- Key repositories by durable GitHub IDs in production, not owner/name.
- Show last sync, stale cache, partial sync, rate limit, SSO, and reconnect states.
```

- [ ] **Step 3: Add execution notes to existing interactive prototype plan**

Add:

```markdown
## Follow-Up Auth Prototype Pass

The next pass is tracked in `Docs/superpowers/plans/2026-05-25-ios-auth-onboarding-prototype.md`. It adds first-run GitHub sign-in, permission rationale, repo setup, privacy defaults, sync/recovery states, and native iOS polish before any SwiftUI implementation.
```

- [ ] **Step 4: Run final verification**

Run:

```bash
npm run verify:ios-mockups
node --check mockups/ios/app.js
node --check scripts/verify-ios-mockups.mjs
git status --short --branch
```

Expected:

```text
iOS interactive prototype verification passed
```

`git status` should show only the intended files before commit.

- [ ] **Step 5: Commit final docs**

Run:

```bash
git add mockups/ios/README.md Docs/superpowers/specs/2026-05-25-ios-interactive-prototype-design.md Docs/superpowers/plans/2026-05-25-ios-interactive-prototype.md
git commit -m "Document iOS auth prototype review states"
```

---

## Acceptance Criteria

- `?auth=signed-out` shows a first-run welcome screen with `Sign in with GitHub` and `Try Demo`.
- `?auth=permissions` explains read-only GitHub permissions before OAuth.
- `?auth=connecting` shows a simulated GitHub authorization progress state.
- `?auth=repo-setup` shows a searchable repo picker with public/private visibility and an SSO-blocked repo.
- `?auth=privacy` shows share privacy defaults and private-detail warnings.
- `?auth=syncing` shows staged initial sync progress.
- `?auth=expired` and `?auth=rate-limit` show recoverable issue states with reconnect/cached-data paths.
- `?empty=no-repos`, `?empty=no-activity`, and `?empty=no-releases` show distinct no-data states.
- `?tab=cards&private-warning=true` shows a private-detail warning before sharing.
- The authenticated Today / Activity / Releases / Cards / More tabs still work.
- The Cards front/back flow, Edit Card sheet, and Share Card sheet still work.
- The prototype looks less web-dashboard-like: native-ish tab behavior, cleaner header, grouped lists, fewer heavy borders, and bottom sheets with a grabber.
- `npm run verify:ios-mockups` passes.
- `node --check mockups/ios/app.js` passes.
- Browser screenshots of welcome, repo setup, and private share warning show no obvious overlap or clipping.

## Self-Review

- **Spec coverage:** The plan covers sign-in, permission rationale, onboarding, repo setup, privacy defaults, sync/loading, auth recovery, no-data states, GitHub gotchas, share privacy warnings, and iOS polish.
- **Placeholder scan:** The plan contains no placeholder implementation steps. Each task specifies exact files, concrete code, commands, expected outcomes, and commit boundaries.
- **Type consistency:** The state fields used across tasks are `authState`, `onboardingStep`, `syncState`, `authIssue`, `emptyState`, `privateShareWarning`, `activeTab`, `activeMoreScreen`, `activeSheet`, `range`, `repoSearch`, `cardSide`, and `cardDraft`. Handler names and render function names match the verifier markers.

## Execution Options

1. **Subagent-Driven (recommended)** - Dispatch a fresh subagent per task, review between tasks, and keep commits small.
2. **Inline Execution** - Execute tasks in this session using executing-plans, with checkpoints after each task.
