const app = document.querySelector("[data-prototype-app]");

const repositories = [
  { id: "prbar", owner: "neonwatty", name: "prbar", visibility: "public", color: "#0ea5e9", included: true, recommended: true, access: "ready", reason: "Most active this week" },
  { id: "launch-kit", owner: "neonwatty", name: "launch-kit", visibility: "public", color: "#16a34a", included: true, recommended: true, access: "ready", reason: "Recent releases" },
  { id: "client-api", owner: "example", name: "client-api", visibility: "private", color: "#f59e0b", included: true, recommended: true, access: "ready", reason: "Private repo included" },
  { id: "docs-site", owner: "neonwatty", name: "docs-site", visibility: "public", color: "#7c3aed", included: false, recommended: false, access: "ready", reason: "Documentation releases" },
  { id: "ops-console", owner: "example", name: "ops-console", visibility: "private", color: "#ef4444", included: false, recommended: false, access: "sso", reason: "Needs SSO authorization" }
];

const pullRequests = [
  { id: "pr-39", title: "Connect GitHub auth fallback", repoId: "prbar", number: 39, mergedAt: "2026-05-24T17:42:00Z" },
  { id: "pr-38", title: "Update GitHub Pages actions", repoId: "prbar", number: 38, mergedAt: "2026-05-24T16:18:00Z" },
  { id: "pr-36", title: "Expand app smoke coverage", repoId: "prbar", number: 36, mergedAt: "2026-05-23T21:04:00Z" },
  { id: "pr-44", title: "Add release smoke harness", repoId: "launch-kit", number: 44, mergedAt: "2026-05-22T18:20:00Z" },
  { id: "pr-77", title: "Harden webhook signature checks", repoId: "client-api", number: 77, mergedAt: "2026-05-21T15:15:00Z" },
  { id: "pr-81", title: "Refresh launch notes template", repoId: "launch-kit", number: 81, mergedAt: "2026-05-20T12:30:00Z" },
  { id: "pr-61", title: "Document release card workflow", repoId: "docs-site", number: 61, mergedAt: "2026-05-19T10:00:00Z" },
  { id: "pr-90", title: "Add incident export view", repoId: "ops-console", number: 90, mergedAt: "2026-05-18T11:10:00Z" }
];

const releases = [
  {
    id: "rel-prbar-140",
    repoId: "prbar",
    title: "GitHub auth fallback",
    tag: "v1.4.0",
    date: "2026-05-24",
    source: "release",
    notes: "Connects GitHub auth fallback, improves live data startup behavior, and preserves the last useful activity view.",
    url: "https://github.com/neonwatty/prbar/releases/tag/v1.4.0"
  },
  {
    id: "rel-prbar-130",
    repoId: "prbar",
    title: "Pages deployment cleanup",
    tag: "v1.3.0",
    date: "2026-05-22",
    source: "release",
    notes: "Updates GitHub Pages Actions, refreshes the landing page, and keeps the public preview current.",
    url: "https://github.com/neonwatty/prbar/releases/tag/v1.3.0"
  },
  {
    id: "tag-launch-100",
    repoId: "launch-kit",
    title: "Tagged v1.0.0",
    tag: "v1.0.0",
    date: "2026-05-21",
    source: "tag",
    notes: "Generated from merged PRs around this tag: release smoke harness and launch notes template.",
    url: "https://github.com/neonwatty/launch-kit/releases/tag/v1.0.0"
  },
  {
    id: "rel-launch-092",
    repoId: "launch-kit",
    title: "Smoke test expansion",
    tag: "v0.9.2",
    date: "2026-05-18",
    source: "release",
    notes: "Expands release smoke coverage and adds a clearer fixture baseline for launch checks.",
    url: "https://github.com/neonwatty/launch-kit/releases/tag/v0.9.2"
  },
  {
    id: "tag-prbar-121",
    repoId: "prbar",
    title: "Tagged v1.2.1",
    tag: "v1.2.1",
    date: "2026-05-16",
    source: "tag",
    notes: "No GitHub Release notes found. PRBar summarized merged PRs around this tag.",
    url: "https://github.com/neonwatty/prbar/releases/tag/v1.2.1"
  },
  {
    id: "rel-client-210",
    repoId: "client-api",
    title: "Webhook reliability update",
    tag: "v2.1.0",
    date: "2026-05-14",
    source: "release",
    notes: "Hardens webhook signature checks and adds clearer retry handling for customer integrations.",
    url: "https://github.com/example/client-api/releases/tag/v2.1.0"
  },
  {
    id: "rel-docs-050",
    repoId: "docs-site",
    title: "Release card docs",
    tag: "v0.5.0",
    date: "2026-05-10",
    source: "release",
    notes: "Adds documentation for creating proof-of-work cards from release metadata.",
    url: "https://github.com/neonwatty/docs-site/releases/tag/v0.5.0"
  }
];

const state = {
  authState: "authenticated",
  onboardingStep: "done",
  syncState: "fresh",
  authIssue: null,
  emptyState: null,
  activeTab: "prs",
  activeMoreScreen: null,
  activeSheet: null,
  selectedPrRepoId: null,
  selectedPrDate: "2026-05-24",
  range: "week",
  releaseRange: "week",
  selectedReleaseDate: "2026-05-24",
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

const navItems = [
  ["prs", "PRs", "▥"],
  ["releases", "Releases", "◇"],
  ["share", "Share", "▣"],
  ["more", "More", "•••"]
];

const moreItems = [
  ["repos", "Repos"],
  ["settings", "Settings"],
  ["privacy", "Privacy"],
  ["sample", "Sample Data"],
  ["about", "About"]
];

const themes = ["clean", "terminal", "launch", "hype", "minimal"];
const ranges = ["day", "week", "month"];
const todayKey = "2026-05-24";

function includedRepos() {
  return repositories.filter((repo) => repo.included);
}

function includedRepoIds() {
  return new Set(includedRepos().map((repo) => repo.id));
}

function repoFor(id) {
  return repositories.find((repo) => repo.id === id);
}

function prsForIncludedRepos() {
  const ids = includedRepoIds();
  return pullRequests.filter((pr) => ids.has(pr.repoId));
}

function releasesForIncludedRepos() {
  const ids = includedRepoIds();
  return releases.filter((release) => ids.has(release.repoId));
}

function filteredRepos() {
  const query = state.repoSearch.trim().toLowerCase();
  if (!query) return repositories;
  return repositories.filter((repo) => `${repo.owner}/${repo.name}`.toLowerCase().includes(query));
}

function selectedRelease() {
  const available = releasesForIncludedRepos();
  const current = available.find((release) => release.id === state.selectedReleaseId);
  return current || available[0] || null;
}

function rangePrs() {
  const all = prsForIncludedRepos();
  const rangeItems = itemsInRange(all, "mergedAt", state.range);
  return state.selectedPrDate ? rangeItems.filter((pr) => dateKey(pr.mergedAt) === state.selectedPrDate) : rangeItems;
}

function itemsInRange(items, dateField, range) {
  const days = range === "day" ? 1 : range === "week" ? 7 : 31;
  const start = addDays(todayKey, -(days - 1));
  return items.filter((item) => {
    const key = dateKey(item[dateField]);
    return key >= start && key <= todayKey;
  });
}

function releaseItemsInRange() {
  const rangeItems = itemsInRange(releasesForIncludedRepos(), "date", state.releaseRange);
  return state.selectedReleaseDate ? rangeItems.filter((release) => release.date === state.selectedReleaseDate) : rangeItems;
}

function dateKey(value) {
  return String(value).slice(0, 10);
}

function addDays(dateText, amount) {
  const date = new Date(`${dateText}T12:00:00`);
  date.setDate(date.getDate() + amount);
  return date.toISOString().slice(0, 10);
}

function dayName(dateText) {
  return new Date(`${dateText}T12:00:00`).toLocaleDateString("en", { weekday: "short" });
}

function rangeDays(range) {
  const count = range === "day" ? 5 : range === "week" ? 7 : 31;
  return Array.from({ length: count }, (_, index) => addDays(todayKey, index - count + 1));
}

function calendarDays(range) {
  if (range !== "month") return rangeDays(range);
  return Array.from({ length: 31 }, (_, index) => `2026-05-${String(index + 1).padStart(2, "0")}`);
}

function formatDate(dateText) {
  return new Date(`${dateText}T12:00:00`).toLocaleDateString("en", { month: "short", day: "numeric" });
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll("\"", "&quot;");
}

function toast(message) {
  state.toast = message;
  render();
  window.setTimeout(() => {
    if (state.toast === message) {
      state.toast = "";
      render();
    }
  }, 1400);
}

function setTab(tab) {
  state.activeTab = tab;
  state.activeMoreScreen = null;
  state.emptyState = null;
  render();
}

function openMore(screen) {
  state.activeTab = "more";
  state.activeMoreScreen = screen;
  state.emptyState = null;
  render();
}

function makeActivityCard() {
  state.activeSheet = null;
  state.cardSide = "front";
  state.privateShareWarning = false;
  state.cardDraft = {
    ...state.cardDraft,
    sourceType: "activity",
    sourceId: null
  };
  setTab("share");
}

function makeReleaseCard(id) {
  state.selectedReleaseId = id;
  state.activeSheet = null;
  state.cardSide = "front";
  state.privateShareWarning = false;
  state.cardDraft = {
    ...state.cardDraft,
    sourceType: "release",
    sourceId: id
  };
  setTab("share");
}

function toggleRepo(id) {
  const repo = repoFor(id);
  if (repo.access === "sso") {
    toast("Authorize SSO before including this repo");
    return;
  }
  repo.included = !repo.included;
  const availableRelease = selectedRelease();
  state.selectedReleaseId = availableRelease?.id || null;
  state.selectedReleaseDate = availableRelease?.date || todayKey;
  render();
}

function resetDemoData() {
  repositories.forEach((repo, index) => {
    repo.included = index < 3;
  });
  state.repoSearch = "";
  state.range = "week";
  state.releaseRange = "week";
  state.selectedPrDate = "2026-05-24";
  state.selectedReleaseDate = "2026-05-24";
  state.activeSheet = null;
  state.cardSide = "front";
  state.selectedReleaseId = "rel-prbar-140";
  state.cardDraft = {
    sourceType: "activity",
    sourceId: null,
    theme: "clean",
    showRepos: true,
    showHandle: true,
    exactCounts: true,
    showPrivateLabels: false
  };
  toast("Demo data reset");
}

function applyInitialRoute() {
  const params = new URLSearchParams(window.location.search);
  const auth = params.get("auth");
  const empty = params.get("empty");
  const tab = params.get("tab");
  const side = params.get("side");
  const sheet = params.get("sheet");
  const repo = params.get("repo");
  const release = params.get("release");
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

  const tabAliases = { activity: "prs", cards: "share" };
  const requestedTab = tabAliases[tab] || tab;
  if (navItems.some(([id]) => id === requestedTab)) state.activeTab = requestedTab;
  if (repoFor(repo)) {
    state.activeTab = "prs";
    state.selectedPrRepoId = repo;
  }
  if (releases.some((item) => item.id === release)) {
    const routedRelease = releases.find((item) => item.id === release);
    state.activeTab = "releases";
    state.selectedReleaseId = release;
    state.selectedReleaseDate = routedRelease.date;
  }
  if (side === "back") state.cardSide = "back";
  if (sheet === "edit" || sheet === "share") state.activeSheet = sheet;
  if (sheet === "share" && cardHasPrivateEvidence()) {
    state.privateShareWarning = true;
  }
  if (privateWarning === "true") {
    state.activeTab = "share";
    state.privateShareWarning = true;
  }
}

function render() {
  app.innerHTML = `
    <div class="app-chrome">
      ${renderHeader()}
      <section class="app-content">
        ${renderActiveScreen()}
      </section>
      ${renderActiveSheet()}
      ${state.toast ? `<div class="toast">${escapeHtml(state.toast)}</div>` : ""}
      ${state.authState === "authenticated" ? renderBottomNav() : ""}
    </div>
  `;
}

function renderHeader() {
  const authenticated = state.authState === "authenticated";
  const activeTitle = state.activeTab === "more" && state.activeMoreScreen
    ? moreItems.find(([id]) => id === state.activeMoreScreen)?.[1]
    : navItems.find(([id]) => id === state.activeTab)?.[1];
  const title = authenticated ? activeTitle : authHeaderTitle();
  return `
    <header class="app-header native-header">
      <div>
        <p class="microcopy">${authenticated ? "Connected as @neonwatty" : "PRBar"}</p>
        <strong>${escapeHtml(title || "Welcome")}</strong>
      </div>
      ${authenticated ? `<button class="screen-heading" type="button" data-action="open-more" data-screen="settings" aria-label="Account settings">@</button>` : ""}
    </header>
  `;
}

function authHeaderTitle() {
  if (state.authState === "issue") {
    return state.authIssue === "rateLimit" ? "Rate Limit" : "Reconnect";
  }
  return {
    welcome: "Welcome",
    permissions: "GitHub Access",
    connecting: "Connecting",
    repos: "Repositories",
    privacy: "Privacy",
    syncing: "Syncing"
  }[state.onboardingStep] || "Welcome";
}

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

function renderActiveScreen() {
  if (state.authState === "signedOut") return renderWelcome();
  if (state.authState === "onboarding") return renderOnboarding();
  if (state.authState === "issue") return renderAuthIssue();
  if (state.emptyState) return renderEmptyState();
  const staleBanner = renderStaleDataBanner();
  if (state.activeTab === "prs") return staleBanner + renderActivity();
  if (state.activeTab === "releases") return staleBanner + renderReleases();
  if (state.activeTab === "share") return staleBanner + renderCards();
  return staleBanner + renderMore();
}

function renderRangeControl(kind = "prs") {
  const activeRange = kind === "releases" ? state.releaseRange : state.range;
  const action = kind === "releases" ? "release-range" : "range";
  return `
    <div class="segmented" aria-label="${kind === "releases" ? "Release" : "PR"} range">
      ${ranges.map((range) => `
        <button type="button" class="${activeRange === range ? "is-active" : ""}" data-action="${action}" data-range="${range}">
          ${range[0].toUpperCase()}${range.slice(1)}
        </button>
      `).join("")}
    </div>
  `;
}

function renderCalendar(kind, items, dateField, selectedDate, range) {
  const counts = new Map();
  items.forEach((item) => {
    const key = dateKey(item[dateField]);
    counts.set(key, (counts.get(key) || 0) + 1);
  });
  const selectAction = kind === "releases" ? "select-release-date" : "select-pr-date";
  const noun = kind === "releases" ? "shipping moments" : "merged PRs";
  const days = calendarDays(range);
  if (range === "month") {
    return `
      <section class="calendar-panel" aria-label="${kind} calendar">
        <div class="calendar-heading">
          <div><p class="microcopy">Calendar</p><h2>May 2026</h2></div>
          <span>${items.length} ${noun}</span>
        </div>
        <div class="month-grid">
          ${["S", "M", "T", "W", "T", "F", "S"].map((label) => `<em>${label}</em>`).join("")}
          ${Array.from({ length: 5 }, () => `<i aria-hidden="true"></i>`).join("")}
          ${days.map((day) => renderCalendarDay(day, counts.get(day) || 0, selectedDate, selectAction)).join("")}
        </div>
      </section>
    `;
  }
  return `
    <section class="calendar-panel" aria-label="${kind} calendar">
      <div class="calendar-heading">
        <div><p class="microcopy">Calendar</p><h2>${range === "day" ? "Pick a day" : "This week"}</h2></div>
        <span>${items.length} ${noun}</span>
      </div>
      <div class="day-strip">
        ${days.map((day) => renderCalendarDay(day, counts.get(day) || 0, selectedDate, selectAction)).join("")}
      </div>
    </section>
  `;
}

function renderCalendarDay(day, count, selectedDate, action) {
  const intensity = count >= 3 ? "is-hot" : count >= 2 ? "is-warm" : count === 1 ? "is-active-day" : "";
  return `
    <button type="button" class="${selectedDate === day ? "is-selected" : ""} ${intensity}" data-action="${action}" data-date="${day}" aria-label="${formatDate(day)} ${count} items">
      <span>${dayName(day)}</span>
      <strong>${Number(day.slice(-2))}</strong>
      <small>${count || ""}</small>
    </button>
  `;
}

function renderActivity() {
  const allRangePrs = itemsInRange(prsForIncludedRepos(), "mergedAt", state.range);
  const prs = rangePrs();
  const total = prs.length;
  const rangeLabel = state.selectedPrDate ? formatDate(state.selectedPrDate) : state.range === "day" ? "Today" : state.range === "week" ? "This week" : "This month";
  const selectedRepo = state.selectedPrRepoId ? repoFor(state.selectedPrRepoId) : null;
  const repoPrs = selectedRepo ? prs.filter((pr) => pr.repoId === selectedRepo.id) : [];
  return `
    <section class="screen stack">
      <section class="section-title">
        <div><p class="microcopy">PRs</p><h1>${selectedRepo ? escapeHtml(selectedRepo.name) : "Shipping rhythm"}</h1></div>
        <button class="small-button" type="button" data-action="open-more" data-screen="repos">Repos</button>
      </section>
      ${renderRangeControl()}
      ${renderCalendar("prs", allRangePrs, "mergedAt", state.selectedPrDate, state.range)}
      ${selectedRepo ? renderActivityRepoDetail(selectedRepo, repoPrs) : renderActivityOverview(prs, total, rangeLabel)}
    </section>
  `;
}

function renderActivityOverview(prs, total, rangeLabel) {
  return `
      <section class="hero-metric">
        <p class="microcopy">${rangeLabel}</p>
        <h1>${total} merged</h1>
        <p>${state.selectedPrDate ? "Activity for the selected calendar day." : state.range === "day" ? "Work landed since morning." : state.range === "week" ? "+28% versus last week. Strong shipping rhythm." : "A strong month across selected repos."}</p>
      </section>
      ${renderChart(prs)}
      <section class="section-title compact-title">
        <div><p class="microcopy">Distribution by repo</p><h2>Tap a repo for PRs</h2></div>
      </section>
      ${renderRepoMix(prs, true)}
      ${renderPrList(prs)}
  `;
}

function renderActivityRepoDetail(repo, prs) {
  return `
    <button class="back-button" type="button" data-action="clear-activity-repo">‹ PRs</button>
    <section class="hero-metric">
      <p class="microcopy">${escapeHtml(repo.visibility)} repository</p>
      <h1>${prs.length} merged</h1>
      <p>Pull requests merged in ${escapeHtml(repo.owner)}/${escapeHtml(repo.name)} for the selected ${state.range}.</p>
    </section>
    ${renderChart(prs)}
    ${renderPrList(prs)}
  `;
}

function renderStaleDataBanner() {
  if (state.syncState !== "stale") return "";
  return `<section class="status-banner"><strong>Last synced 18 minutes ago</strong><p>Showing cached GitHub activity. Pull to refresh in the native app.</p></section>`;
}

function renderReleases() {
  const releaseList = releaseItemsInRange();
  const rangeReleases = itemsInRange(releasesForIncludedRepos(), "date", state.releaseRange);
  const availableRelease = selectedRelease();
  const release = releaseList.find((item) => item.id === state.selectedReleaseId) || releaseList[0] || null;
  if (!availableRelease) {
    return `
      <section class="screen stack">
        <section class="empty-state"><strong>No shipping moments in selected repos</strong><p>Include more repositories to see GitHub Releases and tagged versions.</p></section>
        <button class="primary-action" type="button" data-action="open-more" data-screen="repos">Manage repos</button>
      </section>
    `;
  }
  if (!release) {
    return `
      <section class="screen stack">
        <section class="section-title">
          <div><p class="microcopy">Releases</p><h1>Shipping moments</h1></div>
          <button class="small-button" type="button" data-action="open-more" data-screen="repos">${includedRepos().length} repos</button>
        </section>
        ${renderRangeControl("releases")}
        ${renderCalendar("releases", rangeReleases, "date", state.selectedReleaseDate, state.releaseRange)}
        <section class="empty-state"><strong>No releases on ${formatDate(state.selectedReleaseDate)}</strong><p>Pick another calendar day to inspect release notes, tags, and proof-of-work evidence.</p></section>
      </section>
    `;
  }
  const repo = repoFor(release.repoId);
  return `
    <section class="screen stack">
      <section class="section-title">
        <div><p class="microcopy">Releases</p><h1>Shipping moments</h1></div>
        <button class="small-button" type="button" data-action="open-more" data-screen="repos">${includedRepos().length} repos</button>
      </section>
      ${renderRangeControl("releases")}
      ${renderCalendar("releases", rangeReleases, "date", state.selectedReleaseDate, state.releaseRange)}
      <section class="release-focus">
        <p class="microcopy">Selected ${release.source === "tag" ? "tag" : "release"}</p>
        <h2>${escapeHtml(release.tag)} ${escapeHtml(release.title)}</h2>
        <p>${escapeHtml(repo.name)} · ${formatDate(release.date)} · ${escapeHtml(repo.visibility)} · ${release.source === "tag" ? "generated from PRs" : "official release notes"}</p>
      </section>
      ${renderReleaseTimeline(releaseList, release.id)}
      <section class="notes-panel">
        <strong>${release.source === "tag" ? "Generated tag summary" : "Original release notes"}</strong>
        <p>${escapeHtml(release.notes)}</p>
      </section>
    </section>
  `;
}

function renderReleaseTimeline(releaseList, selectedId) {
  const groups = groupReleasesByDate(releaseList);
  return `
    <section class="release-list" aria-label="Shipping moments timeline">
      ${groups.length ? groups.map(([label, items]) => `
        <div class="release-group">
          <p class="microcopy">${label}</p>
          ${items.map((item) => renderReleaseRow(item, selectedId)).join("")}
        </div>
      `).join("") : `<section class="empty-state compact"><strong>No releases on ${formatDate(state.selectedReleaseDate)}</strong><p>Try another calendar day or switch to the month view.</p></section>`}
    </section>
  `;
}

function groupReleasesByDate(releaseList) {
  const groups = new Map();
  releaseList.forEach((release) => {
    const label = `${dayName(release.date)}, ${formatDate(release.date)}`;
    if (!groups.has(label)) groups.set(label, []);
    groups.get(label).push(release);
  });
  return [...groups.entries()];
}

function renderReleaseRow(item, selectedId) {
  const itemRepo = repoFor(item.repoId);
  const sourceLabel = item.source === "tag" ? "Tag" : "Release";
  return `
    <button type="button" class="release-row ${item.id === selectedId ? "is-selected" : ""}" data-action="select-release" data-release-id="${item.id}">
      <span>
        <strong>${escapeHtml(item.tag)} ${escapeHtml(item.title)}</strong>
        <small>${escapeHtml(itemRepo.name)} · ${formatDate(item.date)} · ${escapeHtml(item.notes)}</small>
      </span>
      <em class="source-badge ${item.source === "tag" ? "is-tag" : ""}">${sourceLabel}</em>
    </button>
  `;
}

function renderCards() {
  const source = cardSource();
  return `
    <section class="screen stack">
      <section class="section-title">
        <div><p class="microcopy">Work cards</p><h1>Create a work card</h1></div>
      </section>
      <section class="source-card">
        <p class="microcopy">Source</p>
        <strong>${escapeHtml(source.title)}</strong>
        <p>${escapeHtml(source.caption)}</p>
      </section>
      ${state.privateShareWarning && cardHasPrivateEvidence() ? renderPrivateShareWarning() : ""}
      <section class="export-summary">
        <p><span>Image</span><strong>${state.cardSide === "front" ? "Public side" : "Evidence side"}</strong></p>
        <p><span>Caption</span><strong>${source.type === "release" ? "Launch note" : "Progress recap"}</strong></p>
      </section>
      ${renderShareCard(source)}
      <section class="card-actions">
        <button class="secondary-action" type="button" data-action="flip-card">${state.cardSide === "front" ? "Show evidence" : "Show public card"}</button>
        <button class="secondary-action" type="button" data-action="open-sheet" data-sheet="edit">Style & Privacy</button>
      </section>
      <button class="primary-action" type="button" data-action="open-sheet" data-sheet="share">Export card</button>
    </section>
  `;
}

function cardSource() {
  if (state.cardDraft.sourceType === "release") {
    const release = releases.find((item) => item.id === state.cardDraft.sourceId) || selectedRelease();
    const repo = repoFor(release.repoId);
    return {
      type: "release",
      title: `Release Receipt · ${release.tag}`,
      metric: release.tag,
      caption: `Based on ${release.source === "tag" ? "tag and PR activity" : "GitHub Release notes"} from ${repo.name} on ${formatDate(release.date)}`,
      repoNames: [repo.name],
      count: 1,
      notes: release.notes
    };
  }
  const prs = rangePrs();
  return {
    type: "activity",
    title: `Shipping Snapshot · ${state.range}`,
    metric: `${prs.length} merged`,
    caption: `Based on ${state.range} merged PR activity from selected repositories`,
    repoNames: [...new Set(prs.map((pr) => repoFor(pr.repoId).name))],
    count: prs.length,
    notes: "A visible proof-of-work snapshot from PRBar."
  };
}

function cardEvidenceRepos() {
  if (state.cardDraft.sourceType === "release") {
    const release = releases.find((item) => item.id === state.cardDraft.sourceId) || selectedRelease();
    return release ? [repoFor(release.repoId)].filter(Boolean) : [];
  }
  const repoIds = new Set([
    ...rangePrs().map((pr) => pr.repoId),
    ...releasesForIncludedRepos().map((release) => release.repoId)
  ]);
  return [...repoIds].map(repoFor).filter(Boolean);
}

function cardHasPrivateEvidence() {
  return cardEvidenceRepos().some((repo) => repo.visibility === "private");
}

function renderShareCard(source) {
  const draft = state.cardDraft;
  if (state.cardSide === "back") {
    return `
      <section class="share-card card-back ${draft.theme}">
        <div>
          <p class="microcopy">Evidence side</p>
          <h2>${source.type === "release" ? "Release receipt" : "Work evidence"}</h2>
          <p>${source.type === "release" ? "GitHub release or tag evidence reviewed before export." : "GitHub activity collected behind the public work card."}</p>
        </div>
        ${renderCardBackEvidence(source)}
        <footer><span>${draft.showHandle ? "@neonwatty" : "handle hidden"}</span><span>evidence side</span></footer>
      </section>
    `;
  }
  const title = draft.exactCounts ? source.metric : source.type === "activity" ? "many merged" : source.metric;
  const repoLine = draft.showRepos ? source.repoNames.join(" · ") : "repos hidden";
  return `
    <section class="share-card ${draft.theme}">
      <div>
          <p class="microcopy">Public side</p>
        <h2>${escapeHtml(title)}</h2>
        <p>${escapeHtml(source.caption)}</p>
      </div>
      <div class="card-bars" aria-label="Card distribution chart">
        <span style="height: 30%"></span><span style="height: 64%"></span><span style="height: 46%"></span><span style="height: 80%"></span><span style="height: 58%"></span><span style="height: 92%"></span>
      </div>
      <footer><span>${draft.showHandle ? "@neonwatty" : "handle hidden"}</span><span>${escapeHtml(repoLine)}</span></footer>
    </section>
  `;
}

function renderPrivateShareWarning() {
  return `
    <section class="status-banner warning">
      <strong>This export may reveal private work</strong>
      <p>Review repo names, exact counts, PR titles, release notes, and the evidence side before exporting.</p>
    </section>
  `;
}

function renderActiveSheet() {
  if (!state.activeSheet) return "";
  const content = state.activeSheet === "edit" ? renderEditSheet() : renderShareSheet();
  return `
    <section class="sheet-backdrop" data-action="close-sheet">
      <div class="bottom-sheet" role="dialog" aria-modal="true">
        <div class="sheet-grabber" aria-hidden="true"></div>
        ${content}
      </div>
    </section>
  `;
}

function renderEditSheet() {
  const draft = state.cardDraft;
  return `
    <header>
      <div><p class="microcopy">Edit card</p><h2>Style and privacy</h2></div>
      <button type="button" class="icon-button" data-action="close-sheet" aria-label="Close">×</button>
    </header>
    <div class="theme-grid" aria-label="Card theme">
      ${themes.map((theme) => `
        <button type="button" class="${draft.theme === theme ? "is-active" : ""}" data-action="theme" data-theme="${theme}">
          ${theme[0].toUpperCase()}${theme.slice(1)}
        </button>
      `).join("")}
    </div>
    <section class="toggle-list sheet-toggles">
      ${toggle("showRepos", "Show repo names")}
      ${toggle("showHandle", "Show GitHub handle")}
      ${toggle("exactCounts", "Use exact counts")}
      ${toggle("showPrivateLabels", "Show private labels")}
    </section>
  `;
}

function renderShareSheet() {
  return `
    <header>
      <div><p class="microcopy">Export card</p><h2>Choose what leaves the app</h2></div>
      <button type="button" class="icon-button" data-action="close-sheet" aria-label="Close">×</button>
    </header>
    <section class="source-card export-note">
      <strong>Images are exported as PNGs</strong>
      <p>Messages and other apps decide how the image and optional caption appear after the iOS Share Sheet opens.</p>
    </section>
    <section class="share-options">
      <button type="button" data-action="share-choice">Share public-side image</button>
      <button type="button" data-action="share-choice">Save image</button>
      <button type="button" data-action="share-choice">Copy image</button>
      <button type="button" data-action="share-choice">Copy caption</button>
      <button type="button" data-action="share-choice">Export evidence side</button>
      <button type="button" data-action="share-choice">Export both sides</button>
    </section>
  `;
}

function renderCardBackEvidence(source) {
  if (source.type === "release") {
    const release = releases.find((item) => item.id === state.cardDraft.sourceId) || selectedRelease();
    const repo = repoFor(release.repoId);
    const relatedPrs = pullRequests.filter((pr) => pr.repoId === release.repoId).slice(0, 3);
    return `
      <div class="evidence-list">
        <strong>${escapeHtml(release.tag)} · ${escapeHtml(repo.name)}</strong>
        <p>${escapeHtml(release.notes)}</p>
        ${relatedPrs.map((pr) => `<span>${escapeHtml(pr.title)}</span>`).join("")}
      </div>
    `;
  }
  const releaseItems = releasesForIncludedRepos().slice(0, 4);
  return `
    <div class="evidence-list">
      ${releaseItems.map((release) => {
        const repo = repoFor(release.repoId);
        return `
          <span><strong>${escapeHtml(release.tag)}</strong> ${escapeHtml(release.title)} · ${escapeHtml(repo.name)}</span>
        `;
      }).join("")}
    </div>
  `;
}

function renderMore() {
  if (state.activeMoreScreen === "repos") return renderRepos();
  if (state.activeMoreScreen === "settings") return renderSettings();
  if (state.activeMoreScreen === "privacy") return renderPrivacy();
  if (state.activeMoreScreen === "sample") return renderSampleData();
  if (state.activeMoreScreen === "about") return renderAbout();
  return `
    <section class="screen stack">
      <section class="section-title"><div><p class="microcopy">More</p><h1>Menu</h1></div></section>
      <section class="menu-list">
        ${moreItems.map(([id, label]) => `
          <button type="button" data-action="open-more" data-screen="${id}"><span>${label}</span><em>${moreDescription(id)}</em></button>
        `).join("")}
      </section>
    </section>
  `;
}

function moreDescription(id) {
  return {
    repos: "Choose included repositories",
    settings: "GitHub, refresh, defaults",
    privacy: "Work-card defaults",
    sample: "Fixture data and reset",
    about: "Prototype context"
  }[id];
}

function renderRepos() {
  const visibleRepos = filteredRepos();
  return `
    <section class="screen stack">
      ${renderBackToMore()}
      <section class="source-card"><strong>Included repos power PRs, Releases, and Cards.</strong><p>${includedRepos().length} of ${repositories.length} repositories included.</p></section>
      <input class="search-input" value="${escapeHtml(state.repoSearch)}" placeholder="Search repos" aria-label="Search repositories" data-action="repo-search">
      <section class="repo-list">
        ${visibleRepos.map((repo) => `
          <label class="${repo.access === "sso" ? "is-blocked" : ""}">
            <input type="checkbox" ${repo.included ? "checked" : ""} ${repo.access === "sso" ? "disabled" : ""} data-action="toggle-repo" data-repo-id="${repo.id}">
            <i style="background:${repo.color}"></i>
            <span>${escapeHtml(repo.name)}</span>
            <em>${repo.access === "sso" ? "SSO required" : `${escapeHtml(repo.visibility)}${repo.included ? "" : " · excluded"}`}</em>
          </label>
        `).join("")}
      </section>
      <button class="primary-action" type="button" data-action="include-all">Include all repos</button>
    </section>
  `;
}

function renderSettings() {
  return `
    <section class="screen stack">
      ${renderBackToMore()}
      <section class="settings-list">
        <p><strong>GitHub</strong><span>Connected</span></p>
        <p><strong>Default range</strong><span>Week</span></p>
        <p><strong>Refresh</strong><span>Manual in prototype</span></p>
        <p><strong>Card privacy</strong><span>${state.cardDraft.showRepos ? "Repo names visible" : "Repos hidden"}</span></p>
      </section>
    </section>
  `;
}

function renderPrivacy() {
  return `
    <section class="screen stack">
      ${renderBackToMore()}
      <section class="toggle-list">
        ${toggle("showRepos", "Show repo names")}
        ${toggle("showHandle", "Show GitHub handle")}
        ${toggle("exactCounts", "Use exact counts")}
        ${toggle("showPrivateLabels", "Show private labels")}
      </section>
      ${renderShareCard(cardSource())}
    </section>
  `;
}

function renderSampleData() {
  return `
    <section class="screen stack">
      ${renderBackToMore()}
      <section class="settings-list">
        <p><strong>Repos</strong><span>${repositories.length}</span></p>
        <p><strong>Merged PRs</strong><span>${pullRequests.length}</span></p>
        <p><strong>GitHub Releases</strong><span>${releases.length}</span></p>
        <p><strong>Network</strong><span>No API calls</span></p>
      </section>
      <button class="primary-action" type="button" data-action="reset-demo">Reset demo data</button>
    </section>
  `;
}

function renderAbout() {
  return `
    <section class="screen stack">
      ${renderBackToMore()}
      <section class="source-card"><strong>PRBar iOS prototype</strong><p>A fixture-backed mobile prototype for checking PR rhythm, browsing GitHub Releases, selecting repos, and sharing proof of work.</p></section>
      <section class="notes-panel"><strong>Not connected to GitHub yet</strong><p>This validates UX before native iOS implementation and real GitHub integration.</p></section>
    </section>
  `;
}

function renderBackToMore() {
  return `<button class="back-button" type="button" data-action="back-more">‹ More</button>`;
}

function renderChart(prs, size = "") {
  const heights = prs.length ? prs.map((_, index) => 30 + ((index * 17 + prs.length * 9) % 62)) : [12, 18, 10];
  return `<div class="chart ${size}">${heights.map((height) => `<span style="height:${height}%"></span>`).join("")}</div>`;
}

function renderRepoMix(prs, interactive = false) {
  const counts = new Map();
  prs.forEach((pr) => counts.set(pr.repoId, (counts.get(pr.repoId) || 0) + 1));
  const maxCount = Math.max(1, ...counts.values());
  const rows = [...counts.entries()].map(([repoId, count]) => {
    const repo = repoFor(repoId);
    const width = Math.max(12, Math.round((count / maxCount) * 100));
    const content = `
      <span><i style="background:${repo.color}"></i>${escapeHtml(repo.name)}</span>
      <b aria-hidden="true"><em style="width:${width}%; background:${repo.color}"></em></b>
      <strong>${count}</strong>
    `;
    if (!interactive) return `<p>${content}</p>`;
    return `<button type="button" data-action="select-activity-repo" data-repo-id="${repo.id}">${content}</button>`;
  });
  return `<section class="repo-mix">${rows.join("") || "<p><span>No included activity</span><strong>0</strong></p>"}</section>`;
}

function renderPrList(prs) {
  return `
    <section class="list-panel">
      <h2>Recent PRs</h2>
      ${prs.map((pr) => `<p><span>${escapeHtml(pr.title)}</span><em>#${pr.number}</em></p>`).join("") || "<p><span>No PRs in this range</span><em></em></p>"}
    </section>
  `;
}

function toggle(key, label) {
  return `
    <label>
      <input type="checkbox" ${state.cardDraft[key] ? "checked" : ""} data-action="privacy-toggle" data-key="${key}">
      <span>${label}</span>
    </label>
  `;
}

app.addEventListener("click", (event) => {
  const target = event.target.closest("[data-action]");
  if (!target) return;
  const action = target.dataset.action;
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
  if (action === "auth-back") {
    state.onboardingStep = target.dataset.step;
    state.authState = target.dataset.step === "welcome" ? "signedOut" : "onboarding";
    render();
  }
  if (action === "auth-cancel") {
    state.authState = "signedOut";
    state.onboardingStep = "welcome";
    toast("GitHub sign-in cancelled");
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
    state.activeTab = "prs";
    render();
  }
  if (action === "reconnect-github") {
    state.authState = "onboarding";
    state.onboardingStep = "permissions";
    state.authIssue = null;
    render();
  }
  if (action === "use-cached-data") {
    state.authState = "authenticated";
    state.authIssue = null;
    state.syncState = "stale";
    toast("Showing cached data");
  }
  if (action === "retry-sync") {
    state.authState = "onboarding";
    state.onboardingStep = "syncing";
    state.authIssue = null;
    state.syncState = "syncing";
    render();
  }
  if (action === "resolve-empty") {
    if (state.emptyState === "no-repos") {
      state.authState = "onboarding";
      state.onboardingStep = "repos";
      state.emptyState = null;
    } else if (state.emptyState === "no-releases") {
      state.activeTab = "releases";
      state.emptyState = null;
    } else {
      state.activeTab = "prs";
      state.emptyState = null;
    }
    render();
  }
  if (action === "nav") setTab(target.dataset.tab);
  if (action === "range") {
    state.range = target.dataset.range;
    state.selectedPrDate = state.range === "month" ? todayKey : state.selectedPrDate;
    state.selectedPrRepoId = null;
    render();
  }
  if (action === "release-range") {
    state.releaseRange = target.dataset.range;
    const visible = itemsInRange(releasesForIncludedRepos(), "date", state.releaseRange);
    const currentVisible = visible.find((release) => release.date === state.selectedReleaseDate);
    const nextRelease = currentVisible || visible[0] || selectedRelease();
    state.selectedReleaseDate = nextRelease?.date || todayKey;
    state.selectedReleaseId = nextRelease?.id || null;
    render();
  }
  if (action === "select-pr-date") {
    state.selectedPrDate = target.dataset.date;
    state.selectedPrRepoId = null;
    render();
  }
  if (action === "select-activity-repo") {
    state.selectedPrRepoId = target.dataset.repoId;
    render();
  }
  if (action === "clear-activity-repo") {
    state.selectedPrRepoId = null;
    render();
  }
  if (action === "make-activity-card") makeActivityCard();
  if (action === "select-release") {
    state.selectedReleaseId = target.dataset.releaseId;
    const release = releases.find((item) => item.id === state.selectedReleaseId);
    state.selectedReleaseDate = release?.date || state.selectedReleaseDate;
    render();
  }
  if (action === "select-release-date") {
    state.selectedReleaseDate = target.dataset.date;
    const dayRelease = itemsInRange(releasesForIncludedRepos(), "date", state.releaseRange).find((release) => release.date === state.selectedReleaseDate);
    if (dayRelease) state.selectedReleaseId = dayRelease.id;
    render();
  }
  if (action === "flip-card") {
    state.cardSide = state.cardSide === "front" ? "back" : "front";
    render();
  }
  if (action === "open-sheet") {
    if (target.dataset.sheet === "share" && cardHasPrivateEvidence()) {
      state.privateShareWarning = true;
    }
    state.activeSheet = target.dataset.sheet;
    render();
  }
  if (action === "close-sheet") {
    if (target.classList.contains("sheet-backdrop") && event.target !== target) return;
    state.activeSheet = null;
    render();
  }
  if (action === "share-choice") {
    state.activeSheet = null;
    toast(`${target.textContent.trim()} ready`);
  }
  if (action === "theme") {
    state.cardDraft.theme = target.dataset.theme;
    render();
  }
  if (action === "open-more") openMore(target.dataset.screen);
  if (action === "back-more") {
    state.activeMoreScreen = null;
    render();
  }
  if (action === "toggle-repo") toggleRepo(target.dataset.repoId);
  if (action === "include-all") {
    repositories.forEach((repo) => {
      repo.included = repo.access !== "sso";
    });
    render();
  }
  if (action === "select-none") {
    repositories.forEach((repo) => {
      if (repo.access !== "sso") repo.included = false;
    });
    render();
  }
  if (action === "authorize-sso") toast("SSO authorization needed in GitHub");
  if (action === "privacy-toggle") {
    state.cardDraft[target.dataset.key] = target.checked;
    render();
  }
  if (action === "reset-demo") resetDemoData();
});

function renderOnboarding() {
  if (state.onboardingStep === "permissions") return renderPermissionRationale();
  if (state.onboardingStep === "connecting") return renderConnecting();
  if (state.onboardingStep === "repos") return renderRepoSetup();
  if (state.onboardingStep === "privacy") return renderPrivacySetup();
  if (state.onboardingStep === "syncing") return renderSyncing();
  return renderWelcome();
}

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
        <p>Included repos power PRs, Releases, and Cards. Private repos are hidden from exported work cards unless you allow them.</p>
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
        <p><span></span>Work card ready</p>
      </section>
      <button class="primary-action" type="button" data-action="finish-sync">View PRBar</button>
    </section>
  `;
}

function renderAuthIssue() {
  const issue = state.authIssue === "rateLimit"
    ? {
        title: "Rate limit reached",
        detail: "GitHub asked PRBar to slow down. Showing the last synced data until the retry window opens.",
        action: "Retry Sync",
        actionName: "retry-sync",
        meta: "Rate limit"
      }
    : {
        title: "Reconnect GitHub",
        detail: "Your GitHub token expired or access was revoked. Reconnect to refresh PRs and releases.",
        action: "Reconnect GitHub",
        actionName: "reconnect-github",
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
      <button class="primary-action" type="button" data-action="${issue.actionName}">${issue.action}</button>
      <button class="secondary-action" type="button" data-action="use-cached-data">Use Cached Data</button>
    </section>
  `;
}

function renderEmptyState() {
  const states = {
    "no-repos": ["No repositories selected", "Choose at least one repo to populate PR stats, releases, and cards.", "Choose repositories"],
    "no-activity": ["No merged PRs yet", "Selected repos have no merged PRs in this range. Try Month or include more repos.", "Open PRs"],
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

app.addEventListener("input", (event) => {
  if (event.target.dataset.action === "repo-search") {
    state.repoSearch = event.target.value;
    render();
  }
});

applyInitialRoute();
render();
