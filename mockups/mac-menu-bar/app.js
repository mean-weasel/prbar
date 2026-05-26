const repositories = [
  { id: "prbar", name: "prbar", owner: "neonwatty", color: "#0ea5e9", included: true, private: false, counts: { day: 5, week: 14, month: 42 } },
  { id: "launch-kit", name: "launch-kit", owner: "neonwatty", color: "#16a34a", included: true, private: false, counts: { day: 2, week: 9, month: 24 } },
  { id: "client-api", name: "client-api", owner: "example", color: "#7c3aed", included: true, private: true, counts: { day: 1, week: 5, month: 18 } },
  { id: "docs-site", name: "docs-site", owner: "neonwatty", color: "#d97706", included: false, private: false, counts: { day: 0, week: 3, month: 8 } }
];

const releases = [
  {
    id: "rel-prbar-140",
    repoId: "prbar",
    tag: "v1.4.0",
    title: "Live data polish",
    date: "May 24",
    source: "release",
    notes: "Connects GitHub auth fallback, improves live data startup behavior, and preserves the last useful activity view."
  },
  {
    id: "rel-launch-100",
    repoId: "launch-kit",
    tag: "v1.0.0",
    title: "Launch workflow",
    date: "May 22",
    source: "tag",
    notes: "Generated from merged PRs around this tag: release smoke harness and launch notes template."
  },
  {
    id: "rel-client-210",
    repoId: "client-api",
    tag: "v2.1.0",
    title: "Webhook retry hardening",
    date: "May 19",
    source: "release",
    notes: "Hardens webhook signature checks and adds clearer retry handling for customer integrations."
  },
  {
    id: "rel-docs-050",
    repoId: "docs-site",
    tag: "v0.5.0",
    title: "Release card docs",
    date: "May 18",
    source: "release",
    notes: "Adds documentation for creating proof-of-work cards from release metadata."
  }
];

const dailyTotals = {
  day: [0, 0, 0, 0, 1, 2, 5],
  week: [3, 4, 2, 6, 3, 5, 5],
  month: [8, 10, 6, 11, 9, 12, 10]
};

const state = {
  tab: "activity",
  range: "week",
  selectedReleaseId: "rel-prbar-140",
  scenario: "default",
  preview: null,
  toast: "",
  refreshed: "9:38 AM"
};

const app = document.querySelector("#app");
const statusTitle = document.querySelector("[data-status-title]");

function includedRepos() {
  return repositories.filter((repo) => repo.included);
}

function visibleReleases() {
  if (state.scenario === "empty") return [];
  const included = new Set(includedRepos().map((repo) => repo.id));
  return releases.filter((release) => included.has(release.repoId));
}

function repoFor(id) {
  return repositories.find((repo) => repo.id === id);
}

function totalForRange(range = state.range) {
  return includedRepos().reduce((sum, repo) => sum + repo.counts[range], 0);
}

function activeRepoCount(range = state.range) {
  return includedRepos().filter((repo) => repo.counts[range] > 0).length;
}

function selectedRelease() {
  const available = visibleReleases();
  return available.find((release) => release.id === state.selectedReleaseId) || available[0] || null;
}

function setTab(tab) {
  state.tab = tab;
  state.toast = "";
  render();
}

function setScenario(scenario) {
  state.scenario = scenario;
  state.tab = scenario === "default" ? state.tab : "releases";
  state.preview = null;
  state.toast = "";
  if (scenario === "tag") state.selectedReleaseId = "rel-launch-100";
  if (scenario === "private") state.selectedReleaseId = "rel-client-210";
  if (scenario === "default") state.selectedReleaseId = "rel-prbar-140";
  render();
}

function setRange(range) {
  state.range = range;
  state.toast = "";
  render();
}

function selectRelease(id) {
  state.selectedReleaseId = id;
  state.toast = "";
  render();
}

function toggleRepo(id) {
  const repo = repositories.find((item) => item.id === id);
  repo.included = !repo.included;
  const currentRelease = selectedRelease();
  state.selectedReleaseId = currentRelease?.id || null;
  state.toast = "";
  render();
}

function openPreview(type) {
  state.preview = type;
  state.toast = "";
  render();
}

function closePreview() {
  state.preview = null;
  state.toast = "";
  render();
}

function exportAction(action) {
  state.toast = `${action} simulated for this prototype.`;
  render();
}

function render() {
  statusTitle.textContent = `${totalForRange("week")} PRs`;
  updateScenarioControls();
  app.innerHTML = `
    <div class="app">
      ${renderHeader()}
      ${renderTabs()}
      <div class="content">
        ${state.tab === "activity" ? renderActivity() : ""}
        ${state.tab === "releases" ? renderReleases() : ""}
        ${state.tab === "settings" ? renderSettings() : ""}
      </div>
      ${state.preview ? renderPreviewSheet() : ""}
    </div>
  `;
}

function updateScenarioControls() {
  document.querySelectorAll("[data-scenario]").forEach((button) => {
    button.classList.toggle("is-active", button.dataset.scenario === state.scenario);
  });
}

function renderHeader() {
  return `
    <header class="header">
      <div class="title-stack">
        <h2>PR Activity</h2>
        <p>${totalForRange()} merged across ${activeRepoCount()} repos · Last refreshed ${state.refreshed}</p>
      </div>
      <button class="refresh" type="button" data-action="refresh">Refresh</button>
    </header>
  `;
}

function renderTabs() {
  const tabs = [
    ["activity", "Activity"],
    ["releases", "Releases"],
    ["settings", "Settings"]
  ];
  return `
    <nav class="tabs" aria-label="Popover tabs">
      ${tabs.map(([id, label]) => `
        <button class="tab" type="button" data-tab="${id}" aria-selected="${state.tab === id}">${label}</button>
      `).join("")}
    </nav>
  `;
}

function renderActivity() {
  const total = totalForRange();
  return `
    <section class="screen">
      <div class="segment" aria-label="Activity range">
        ${["day", "week", "month"].map((range) => `
          <button type="button" class="${state.range === range ? "is-active" : ""}" data-range="${range}">${titleCase(range)}</button>
        `).join("")}
      </div>

      <div class="tile-grid">
        <div class="metric"><strong>${total}</strong><span>merged</span></div>
        <div class="metric"><strong>${activeRepoCount()}</strong><span>repos</span></div>
        <div class="metric"><strong>${state.range === "day" ? 1 : state.range === "week" ? 7 : 31}</strong><span>days</span></div>
      </div>

      <section class="panel">
        <div class="panel-title">
          <h3>Merged PRs</h3>
          <span class="micro">${titleCase(state.range)} view</span>
        </div>
        ${renderChart()}
      </section>

      <section class="panel repo-mix">
        <div class="panel-title">
          <h3>Repo mix</h3>
          <span class="micro">Included only</span>
        </div>
        ${includedRepos().map((repo) => renderRepoLine(repo)).join("") || `<p class="notes">No repositories included.</p>`}
      </section>

      <div class="actions">
        <button class="primary-action" type="button" data-preview="pr">Share PR Card</button>
        <button class="secondary-action" type="button" data-tab="settings">Edit Repos</button>
      </div>
    </section>
  `;
}

function renderChart() {
  const totals = dailyTotals[state.range];
  const max = Math.max(...totals, 1);
  const labels = state.range === "month"
    ? ["W1", "W2", "W3", "W4", "W5", "W6", "Now"]
    : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  return `
    <div class="chart" aria-label="Stacked activity chart">
      ${totals.map((total, index) => {
        const height = Math.max((total / max) * 94, total > 0 ? 8 : 0);
        const repoSegments = includedRepos().slice(0, 3);
        return `
          <div class="bar-cell" title="${labels[index]}: ${total} merged">
            <div class="bar-stack" style="height:${height}px">
              ${repoSegments.map((repo, segmentIndex) => `
                <span class="bar-segment" style="height:${Math.max(height / (repoSegments.length + segmentIndex), 4)}px;background:${repo.color}"></span>
              `).join("")}
            </div>
            <small>${labels[index]}</small>
          </div>
        `;
      }).join("")}
    </div>
  `;
}

function renderRepoLine(repo) {
  return `
    <div class="repo-line">
      <div class="repo-name">
        <span class="dot" style="background:${repo.color}"></span>
        <span>${repo.private ? "Private repo" : repo.name}</span>
      </div>
      <strong>${repo.counts[state.range]}</strong>
    </div>
  `;
}

function renderReleases() {
  const selected = selectedRelease();
  const items = visibleReleases();
  if (!selected) {
    return `
      <section class="screen">
      <section class="notice">
        <strong>No releases in included repositories</strong>
        <p>Include more repositories in Settings to see GitHub Releases and tagged versions.</p>
      </section>
        <button class="secondary-action" type="button" data-tab="settings">Edit Repos</button>
      </section>
    `;
  }

  return `
    <section class="screen">
      <section class="release-list" aria-label="Shipping moments">
        ${items.map((release) => renderReleaseRow(release, selected.id)).join("")}
      </section>

      <section class="panel">
        <div class="panel-title">
          <div>
            <span class="micro">${selected.source === "tag" ? "Generated tag summary" : "Original release notes"}</span>
            <h3>${selected.tag} ${selected.title}</h3>
          </div>
          <span class="badge ${selected.source === "tag" ? "tag" : ""}">${selected.source === "tag" ? "Tag" : "Release"}</span>
        </div>
        <p class="notes">${selected.notes}</p>
      </section>

      <div class="actions">
        <button class="primary-action" type="button" data-preview="release">Share Release Card</button>
        <button class="secondary-action" type="button" data-copy-notes>Copy Notes</button>
      </div>
      ${state.toast && !state.preview ? `<div class="toast">${state.toast}</div>` : ""}
    </section>
  `;
}

function renderReleaseRow(release, selectedId) {
  const repo = repoFor(release.repoId);
  const repoName = repo.private ? "Private repo" : repo.name;
  return `
    <button class="release-row ${release.id === selectedId ? "is-selected" : ""}" type="button" data-release="${release.id}">
      <div class="release-meta">
        <strong>${release.tag} ${release.title}</strong>
        <span class="badge ${release.source === "tag" ? "tag" : ""}">${release.source === "tag" ? "Tag" : "Release"}</span>
      </div>
      <p>${repoName} · ${release.date} · ${release.notes}</p>
    </button>
  `;
}

function renderSettings() {
  return `
    <section class="screen">
      <section class="notice">
        <strong>Share defaults</strong>
        <p>Fixed cards hide private repository names and show a preview before export.</p>
      </section>

      <section class="panel settings-list">
        <div class="panel-title">
          <h3>Included repositories</h3>
          <span class="micro">Affects Activity and Releases</span>
        </div>
        ${repositories.map((repo) => `
          <div class="settings-row">
            <label>
              <input type="checkbox" ${repo.included ? "checked" : ""} data-toggle-repo="${repo.id}">
              <span class="dot" style="background:${repo.color}"></span>
              <strong>${repo.name}</strong>
            </label>
            <span>${repo.private ? "private" : "public"} · ${repo.counts.week} this week</span>
          </div>
        `).join("")}
      </section>
    </section>
  `;
}

function renderPreviewSheet() {
  const isRelease = state.preview === "release";
  const selected = selectedRelease();
  const releaseRepo = selected ? repoFor(selected.repoId) : null;
  const privacyText = isRelease && releaseRepo?.private
    ? "Privacy warning: this release comes from a private repository, so the repo name is hidden."
    : "Privacy applied: private repository names are hidden before export.";
  return `
    <div class="sheet-backdrop" role="dialog" aria-modal="true" aria-label="${isRelease ? "Release card preview" : "PR card preview"}">
      <section class="sheet">
        <header class="sheet-header">
          <h3>${isRelease ? "Release Card Preview" : "PR Card Preview"}</h3>
          <button class="icon-action" type="button" data-close-preview aria-label="Close preview">×</button>
        </header>
        <div class="sheet-body">
          ${isRelease ? renderReleaseCard(selected, releaseRepo) : renderPRCard()}
          <div class="privacy-row ${isRelease && releaseRepo?.private ? "warning" : ""}">${privacyText}</div>
          <div class="export-grid">
            <button class="primary-action" type="button" data-export="Share">Share</button>
            <button class="secondary-action" type="button" data-export="Copy Image">Copy Image</button>
            <button class="secondary-action" type="button" data-export="Save PNG">Save PNG</button>
          </div>
          ${state.toast ? `<div class="toast">${state.toast}</div>` : ""}
        </div>
      </section>
    </div>
  `;
}

function renderPRCard() {
  const values = dailyTotals[state.range];
  const repos = includedRepos()
    .filter((repo) => repo.counts[state.range] > 0)
    .sort((a, b) => b.counts[state.range] - a.counts[state.range])
    .slice(0, 4);
  return `
    <article class="share-card pr">
      <div class="share-card-inner">
        <span class="card-kicker">PRBar · ${titleCase(state.range)} proof of work</span>
        <h4>${totalForRange()} merged PRs ${state.range === "day" ? "today" : `this ${state.range}`}</h4>
        <p>${activeRepoCount()} active repos, with private repository names hidden by default.</p>
        <div class="mini-chart" aria-hidden="true">
          ${values.map((value) => `<i style="height:${Math.max(value * 6, 8)}px"></i>`).join("")}
        </div>
        <div class="card-repo-mix" aria-label="Merged pull requests by repository">
          ${repos.map((repo) => `
            <div class="card-repo-row">
              <span>
                <i style="background:${repo.color}"></i>
                ${repo.private ? "Private repo" : repo.name}
              </span>
              <strong>${repo.counts[state.range]}</strong>
            </div>
          `).join("")}
        </div>
        <footer class="card-footer">
          <span>@neonwatty</span>
          <span>prbar.app</span>
        </footer>
      </div>
    </article>
  `;
}

function renderReleaseCard(release, repo) {
  const repoName = repo?.private ? "Private repo" : repo?.name || "Selected repo";
  const source = release?.source === "tag" ? "Tag-derived summary" : "GitHub Release notes";
  return `
    <article class="share-card release">
      <div class="share-card-inner">
        <span class="card-kicker">PRBar · ${source}</span>
        <h4>${release?.tag || "v1.0.0"} ${release?.title || "Release shipped"}</h4>
        <p>${repoName} · ${release?.date || "May 2026"}</p>
        <p>${release?.notes || "Release notes preview."}</p>
        <footer class="card-footer">
          <span>@neonwatty</span>
          <span>prbar.app</span>
        </footer>
      </div>
    </article>
  `;
}

function titleCase(value) {
  return value.slice(0, 1).toUpperCase() + value.slice(1);
}

app.addEventListener("click", (event) => {
  const target = event.target.closest("button, input");
  if (!target) return;

  if (target.dataset.tab) setTab(target.dataset.tab);
  if (target.dataset.range) setRange(target.dataset.range);
  if (target.dataset.release) selectRelease(target.dataset.release);
  if (target.dataset.preview) openPreview(target.dataset.preview);
  if (target.dataset.closePreview !== undefined) closePreview();
  if (target.dataset.export) exportAction(target.dataset.export);
  if (target.dataset.copyNotes !== undefined) exportAction("Release notes copied");
});

app.addEventListener("change", (event) => {
  const target = event.target;
  if (target.dataset.toggleRepo) toggleRepo(target.dataset.toggleRepo);
});

document.querySelector("#menuButton").addEventListener("click", () => {
  app.classList.toggle("is-highlighted");
});

document.querySelectorAll("[data-scenario]").forEach((button) => {
  button.addEventListener("click", () => setScenario(button.dataset.scenario));
});

render();
