const routes = [
  { id: "home", label: "Home" },
  { id: "network", label: "Network" },
  { id: "boards", label: "Boards" },
  { id: "talent", label: "Talent" },
  { id: "dashboard", label: "Dashboard" },
  { id: "trust", label: "Trust" },
];

const secondaryRoutes = [
  { id: "profile", label: "Profile" },
  { id: "receipt", label: "Receipt" },
  { id: "project", label: "Project" },
  { id: "repos", label: "Repos" },
  { id: "studio", label: "Studio" },
];

const builder = {
  name: "Maya Chen",
  handle: "@maya.codes",
  avatar: "MC",
  role: "AI product builder",
  tools: ["Claude Code", "Cursor", "GitHub Actions"],
  stats: [
    { label: "PRs merged", value: "118" },
    { label: "Releases", value: "14" },
    { label: "Projects", value: "11" },
    { label: "Day streak", value: "9" },
  ],
};

const release = {
  title: "SideProject Radar v2.1",
  type: "Release Receipt",
  summary: "8 PRs merged across 2 repos with release notes imported.",
  signals: ["feature shipped", "tests added", "release tagged"],
};

const projects = [
  {
    name: "SideProject Radar",
    summary: "Founder discovery dashboard with selected repo proof.",
    status: "shipped",
    receipts: 6,
  },
  {
    name: "AI Onboarding Flow",
    summary: "Activation workflow rebuilt from customer support findings.",
    status: "launched",
    receipts: 4,
  },
  {
    name: "PRBar Studio",
    summary: "Card generator for public proof-of-work artifacts.",
    status: "building",
    receipts: 3,
  },
];

const feed = [
  { actor: "@maya.codes", action: "merged 7 PRs", target: "SideProject Radar" },
  { actor: "@nora.ship", action: "published a receipt", target: "Launch Sprint Kit" },
  { actor: "@devon.codes", action: "tagged a release", target: "iOS Proof Cards" },
];

const boards = [
  { rank: 1, handle: "@maya.codes", metric: "42 PRs", detail: "4 releases this week" },
  { rank: 2, handle: "@jules.dev", metric: "31 PRs", detail: "2 releases this week" },
  { rank: 3, handle: "@rio.ai", metric: "24 PRs", detail: "5 releases this week" },
  { rank: 4, handle: "@devon.codes", metric: "21 PRs", detail: "11 day streak" },
];

const talent = [
  {
    handle: "@nora.ship",
    summary: "Cursor, SaaS dashboards, 3 releases this month.",
    tags: ["available", "saas", "cursor"],
  },
  {
    handle: "@devon.codes",
    summary: "Claude Code, iOS, strong release-card history.",
    tags: ["available", "mobile", "claude"],
  },
  {
    handle: "@rhea.builds",
    summary: "AI app builder with founder-friendly weekly shipping cadence.",
    tags: ["saas", "mobile", "founder"],
  },
];

const repos = [
  { name: "sideproject-radar", visibility: "public", selected: true, prs: 46 },
  { name: "ai-onboarding-flow", visibility: "private", selected: true, prs: 22 },
  { name: "proof-card-studio", visibility: "public", selected: false, prs: 18 },
];

const sampleData = {
  builder,
  release,
  projects,
  feed,
  boards,
  talent,
  repos,
};

const app = document.querySelector("#app");
const nav = document.querySelector(".nav-links");
const headerAction = document.querySelector(".header-action");
const modal = document.querySelector("#early-access-modal");
const hasAppShell = app && nav && headerAction && modal;

function routeIdFromHash() {
  const hash = window.location.hash.replace(/^#\/?/, "").trim();
  const id = hash.split("/")[0] || "home";
  const routeIds = [...routes, ...secondaryRoutes].map((route) => route.id);

  return routeIds.includes(id) ? id : "home";
}

function linkTo(routeId) {
  return `#/${routeId}`;
}

function tags(items) {
  return items.map((item) => `<span>${item}</span>`).join("");
}

function render(html) {
  app.innerHTML = html;
}

function renderRoute() {
  const routeId = routeIdFromHash();
  const views = {
    home: renderHome,
    network: renderNetwork,
    boards: renderBoards,
    talent: renderTalent,
    dashboard: renderDashboard,
    trust: renderTrust,
    profile: renderProfile,
    receipt: renderReceipt,
    project: renderProject,
    repos: renderRepos,
    studio: renderStudio,
  };

  if (nav) {
    nav.innerHTML = routes
      .map(
        (route) =>
          `<a href="${linkTo(route.id)}" ${route.id === routeId ? 'aria-current="page"' : ""}>${route.label}</a>`
      )
      .join("");
  }

  views[routeId]();
}

function renderHome() {
  render(`
    <section class="hero" aria-labelledby="hero-title">
      <div class="hero-content">
        <p class="hero-label">Verified GitHub velocity for AI-native builders</p>
        <h1 id="hero-title">Show the world your receipts.</h1>
        <p class="hero-lede">
          <strong>Token usage does not count.</strong> PRBar tracks features shipped,
          PRs merged, releases made, and projects launched so proof comes from work
          that landed.
        </p>
        <div class="hero-actions">
          <a class="primary-action" href="${linkTo("profile")}">View profile</a>
          <a class="secondary-action" href="${linkTo("network")}">Explore network</a>
        </div>
      </div>
    </section>
  `);
}

function renderNetwork() {
  render(`
    <section class="section-pad" aria-labelledby="network-title">
      <div class="section-heading">
        <span>Proof Network</span>
        <h1 id="network-title">Proof Network</h1>
        <p>Follow builders through receipts, releases, projects, and verified repo momentum.</p>
      </div>
      <div class="proof-stack">${sampleData.feed
        .map(
          (item) => `
            <article class="release-card">
              <div>
                <span>${item.actor}</span>
                <h3>${item.action}</h3>
                <p>${item.target}</p>
              </div>
            </article>
          `
        )
        .join("")}</div>
    </section>
  `);
}

function renderProfile() {
  render(`
    <section class="section-pad" aria-labelledby="profile-title">
      <div class="section-heading compact">
        <span>${sampleData.builder.handle}</span>
        <h1 id="profile-title">Receipts beat resumes.</h1>
        <p>${sampleData.builder.role} using ${sampleData.builder.tools.join(", ")}.</p>
      </div>
      <article class="profile-card">
        <div class="profile-header">
          <div class="avatar">${sampleData.builder.avatar}</div>
          <div>
            <h3>${sampleData.builder.name}</h3>
            <p>${sampleData.builder.handle}</p>
          </div>
          <span>Verified</span>
        </div>
        <div class="profile-stats">${sampleData.builder.stats
          .map((stat) => `<div><strong>${stat.value}</strong><span>${stat.label}</span></div>`)
          .join("")}</div>
      </article>
    </section>
  `);
}

function renderReceipt() {
  render(`
    <section class="section-pad" aria-labelledby="receipt-title">
      <div class="section-heading compact">
        <span>${sampleData.release.type}</span>
        <h1 id="receipt-title">Release Receipt</h1>
        <p>${sampleData.release.summary}</p>
      </div>
      <article class="release-card">
        <div>
          <span>${sampleData.release.title}</span>
          <h3>${sampleData.release.type}</h3>
          <div class="talent-tags">${tags(sampleData.release.signals)}</div>
        </div>
      </article>
    </section>
  `);
}

function renderProject() {
  const project = sampleData.projects[0];

  render(`
    <section class="section-pad" aria-labelledby="project-title">
      <div class="section-heading compact">
        <span>${project.status}</span>
        <h1 id="project-title">Project Page</h1>
        <p>${project.name}: ${project.summary}</p>
      </div>
      <a class="secondary-action" href="${linkTo("receipt")}">${project.receipts} receipts</a>
    </section>
  `);
}

function renderBoards() {
  render(`
    <section class="boards-section section-pad" aria-labelledby="boards-title">
      <div class="section-heading compact">
        <span>High-vibe leaderboards</span>
        <h1 id="boards-title">Momentum Boards</h1>
        <p>Rank builders by PRs merged, releases made, active streaks, and project momentum.</p>
      </div>
      <div class="leaderboard">${sampleData.boards
        .map(
          (row) => `
            <article class="leader-row">
              <strong>#${row.rank}</strong>
              <div>
                <strong>${row.handle}</strong>
                <span>${row.detail}</span>
              </div>
              <strong>${row.metric}</strong>
            </article>
          `
        )
        .join("")}</div>
    </section>
  `);
}

function renderTalent() {
  render(`
    <section class="talent-section section-pad" aria-labelledby="talent-title">
      <div class="section-heading compact">
        <span>AI Builder Talent Board</span>
        <h1 id="talent-title">Who can help me ship this?</h1>
        <p>Find builders whose profiles are backed by release history and repo focus.</p>
      </div>
      <div class="talent-grid">${sampleData.talent
        .map(
          (person) => `
            <article class="talent-card">
              <h3>${person.handle}</h3>
              <p>${person.summary}</p>
              <div class="talent-tags">${tags(person.tags)}</div>
            </article>
          `
        )
        .join("")}</div>
    </section>
  `);
}

function renderDashboard() {
  render(`
    <section class="section-pad" aria-labelledby="dashboard-title">
      <div class="section-heading compact">
        <span>Private dashboard</span>
        <h1 id="dashboard-title">Receipt Command Center</h1>
        <p>Select repos, review proof signals, and publish receipts from one place.</p>
      </div>
      <div class="apps-grid">${sampleData.projects
        .map(
          (project) => `
            <article>
              <h3>${project.name}</h3>
              <p>${project.summary}</p>
              <span>${project.receipts} receipts</span>
            </article>
          `
        )
        .join("")}</div>
    </section>
  `);
}

function renderRepos() {
  render(`
    <section class="section-pad" aria-labelledby="repos-title">
      <div class="section-heading compact">
        <span>Connected GitHub</span>
        <h1 id="repos-title">Proof Sources</h1>
        <p>Choose which repositories count toward public proof.</p>
      </div>
      <div class="leaderboard">${sampleData.repos
        .map(
          (repo) => `
            <article class="leader-row">
              <strong>${repo.name}</strong>
              <span>${repo.visibility}</span>
              <span>${repo.selected ? "selected" : "paused"}</span>
              <strong>${repo.prs} PRs</strong>
            </article>
          `
        )
        .join("")}</div>
    </section>
  `);
}

function renderStudio() {
  render(`
    <section class="section-pad" aria-labelledby="studio-title">
      <div class="section-heading compact">
        <span>Shareable cards</span>
        <h1 id="studio-title">Receipt Studio</h1>
        <p>Compose public proof cards from releases, projects, and selected repo activity.</p>
      </div>
      <article class="release-card">
        <div>
          <span>${sampleData.release.title}</span>
          <h3>${sampleData.release.type}</h3>
          <p>${sampleData.release.summary}</p>
        </div>
      </article>
    </section>
  `);
}

function renderTrust() {
  render(`
    <section class="section-pad" aria-labelledby="trust-title">
      <div class="section-heading compact">
        <span>Privacy and verification</span>
        <h1 id="trust-title">Trust Center</h1>
        <p>Hide private repo names, select what counts, and keep token usage out of public proof.</p>
      </div>
    </section>
  `);
}

function openModal() {
  modal.hidden = false;
}

if (hasAppShell) {
  window.addEventListener("hashchange", renderRoute);

  headerAction.href = "#";
  headerAction.addEventListener("click", (event) => {
    event.preventDefault();
    openModal();
  });

  document.querySelectorAll("[data-close-modal]").forEach((control) => {
    control.addEventListener("click", () => {
      modal.hidden = true;
    });
  });

  if (!window.location.hash) {
    window.location.hash = linkTo("home");
  } else {
    renderRoute();
  }
}
