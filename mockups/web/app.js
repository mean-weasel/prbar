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

function statGrid(stats) {
  return `
    <div class="profile-stats">
      ${stats.map((stat) => `<div><strong>${stat.value}</strong><span>${stat.label}</span></div>`).join("")}
    </div>
  `;
}

function proofCard(title, body, routeId, meta = "Verified GitHub") {
  return `
    <article class="release-card">
      <div>
        <span>${meta}</span>
        <h3>${title}</h3>
        <p>${body}</p>
      </div>
      <a class="secondary-action" href="${linkTo(routeId)}">Open</a>
    </article>
  `;
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
          <strong>Token usage does not count.</strong> PRBar turns selected GitHub activity into
          public proof of features shipped, PRs merged, releases made, and projects launched.
        </p>
        <div class="hero-actions">
          <a class="primary-action" href="${linkTo("profile")}">Claim your profile</a>
          <a class="secondary-action" href="${linkTo("network")}">Scout builders</a>
        </div>
      </div>
    </section>
    <section class="section-pad" aria-labelledby="home-proof-title">
      <div class="section-heading compact">
        <span>Featured receipt</span>
        <h2 id="home-proof-title">${sampleData.release.title}</h2>
        <p>${sampleData.release.summary}</p>
      </div>
      ${proofCard(
        sampleData.release.type,
        `${sampleData.builder.handle} shipped ${sampleData.release.signals.join(", ")} from selected repo activity.`,
        "receipt",
        "Release receipt"
      )}
      <div class="apps-grid">
        ${proofCard("Builder profile", `${sampleData.builder.name} is showing tools, stats, and GitHub-backed shipping history.`, "profile")}
        ${proofCard("Project operating history", `${sampleData.projects[0].name} has ${sampleData.projects[0].receipts} receipts and a visible release trail.`, "project")}
        ${proofCard("Momentum Boards", "Rank builders by merged work, releases, projects, and recent momentum.", "boards")}
      </div>
    </section>
  `);
}

function renderNetwork() {
  render(`
    <section class="section-pad" aria-labelledby="network-title">
      <div class="section-heading">
        <span>Proof Network</span>
        <h1 id="network-title">People and projects first. GitHub proof underneath.</h1>
        <p>Scout builders by what they shipped, then inspect the receipts and source signals behind the story.</p>
      </div>
      <div class="apps-grid">
        <div class="proof-stack">${sampleData.feed
          .map(
            (item) => `
              <article class="release-card">
                <div>
                  <span>${item.actor}</span>
                  <h3>${item.action}</h3>
                  <p>${item.target}</p>
                </div>
                <a class="secondary-action" href="${linkTo("receipt")}">Receipt</a>
              </article>
            `
          )
          .join("")}</div>
        <aside class="profile-card" aria-label="Source panel">
          <div class="profile-header">
            <div class="avatar">${sampleData.builder.avatar}</div>
            <div>
              <h3>${sampleData.builder.name}</h3>
              <p>${sampleData.builder.role}</p>
            </div>
            <span>Live proof</span>
          </div>
          ${statGrid(sampleData.builder.stats)}
          <div class="talent-tags">${tags(sampleData.builder.tools)}</div>
          <p>${sampleData.repos.filter((repo) => repo.selected).length} selected repos contribute to public proof. Private details stay controlled by the builder.</p>
        </aside>
      </div>
    </section>
  `);
}

function renderProfile() {
  const featuredProject = sampleData.projects[0];

  render(`
    <section class="section-pad" aria-labelledby="profile-title">
      <div class="section-heading compact">
        <span>${sampleData.builder.handle}</span>
        <h1 id="profile-title">Receipts beat resumes.</h1>
        <p>${sampleData.builder.role} with a public trail of selected GitHub work.</p>
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
        <div class="talent-tags">${tags(sampleData.builder.tools)}</div>
        ${statGrid(sampleData.builder.stats)}
        <div class="release-card">
          <div>
            <span>Hiring signal</span>
            <h3>Ships AI product work in public</h3>
            <p>${sampleData.builder.name} has ${sampleData.release.summary.toLowerCase()} Recruiters and founders can inspect receipts instead of guessing from a resume.</p>
          </div>
        </div>
      </article>
      <div class="apps-grid">
        ${proofCard(sampleData.release.title, sampleData.release.summary, "receipt", sampleData.release.type)}
        ${proofCard(featuredProject.name, featuredProject.summary, "project", `${featuredProject.receipts} receipts`)}
      </div>
    </section>
  `);
}

function renderReceipt() {
  const mergedPrs = [
    { title: "Add founder discovery filters", repo: "sideproject-radar", merged: "#184" },
    { title: "Import release notes from GitHub tags", repo: "sideproject-radar", merged: "#188" },
    { title: "Cover radar scoring with regression tests", repo: "ai-onboarding-flow", merged: "#57" },
  ];

  render(`
    <section class="section-pad" aria-labelledby="receipt-title">
      <div class="section-heading compact">
        <span>${sampleData.release.type}</span>
        <h1 id="receipt-title">${sampleData.release.title}</h1>
        <p>Repo sideproject-radar · tag v2.1 · published this week by ${sampleData.builder.handle}</p>
      </div>
      <article class="release-card">
        <div>
          <span>Release receipt</span>
          <h3>Notes</h3>
          <p>${sampleData.release.summary} This receipt highlights shipped product surface, verification work, and tagged release history.</p>
          <div class="talent-tags">${tags(sampleData.release.signals)}</div>
        </div>
      </article>
      <div class="apps-grid">
        ${proofCard("Proof summary", "8 merged PRs, 2 source repos, release tag present, and notes imported from GitHub.", "repos")}
        ${proofCard("Builder context", `${sampleData.builder.name} connected ${sampleData.repos.filter((repo) => repo.selected).length} repos for this public proof surface.`, "profile")}
      </div>
      <div class="leaderboard" aria-label="Merged PR rows">
        ${mergedPrs
          .map(
            (pr) => `
              <article class="leader-row">
                <strong>${pr.merged}</strong>
                <div>
                  <strong>${pr.title}</strong>
                  <span>${pr.repo}</span>
                </div>
                <span>merged</span>
              </article>
            `
          )
          .join("")}
      </div>
    </section>
  `);
}

function renderProject() {
  const project = sampleData.projects[0];
  const timeline = [
    { label: "Discovery filters merged", detail: "Feature PRs landed in selected repo" },
    { label: "Release notes imported", detail: "GitHub tag connected to public receipt" },
    { label: "Radar scoring tested", detail: "Tests added before v2.1 publish" },
  ];

  render(`
    <section class="section-pad" aria-labelledby="project-title">
      <div class="section-heading compact">
        <span>${project.status}</span>
        <h1 id="project-title">SideProject Radar operating history.</h1>
        <p>${project.name}: ${project.summary}</p>
      </div>
      <div class="apps-grid">
        ${proofCard("Shipping signal", `${project.receipts} receipts, ${sampleData.release.summary.toLowerCase()}`, "receipt")}
        ${proofCard("Current status", `${project.name} is ${project.status} and backed by selected GitHub proof.`, "network")}
      </div>
      <div class="leaderboard" aria-label="Proof timeline">
        ${timeline
          .map(
            (item, index) => `
              <article class="leader-row">
                <strong>${index + 1}</strong>
                <div>
                  <strong>${item.label}</strong>
                  <span>${item.detail}</span>
                </div>
                <span>verified</span>
              </article>
            `
          )
          .join("")}
      </div>
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
      <div class="hero-actions" role="group" aria-label="Board views">
        <button class="secondary-action" type="button" data-board="rising">Rising builders</button>
        <button class="secondary-action" type="button" data-board="projects">Projects</button>
        <button class="secondary-action" type="button" data-board="releases">Releases</button>
      </div>
      <div data-board-output></div>
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
        <p>Filter builders by availability, launch surface, mobile skill, and SaaS shipping history.</p>
      </div>
      <div class="hero-actions" role="group" aria-label="Talent filters">
        <button class="secondary-action active" type="button" data-filter="all">All</button>
        <button class="secondary-action" type="button" data-filter="available">Available</button>
        <button class="secondary-action" type="button" data-filter="launch">Launch</button>
        <button class="secondary-action" type="button" data-filter="mobile">Mobile</button>
        <button class="secondary-action" type="button" data-filter="saas">SaaS</button>
      </div>
      <div class="talent-grid" data-talent-output>${sampleData.talent
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
  const proofStats = [
    { label: "Active repos", value: sampleData.repos.filter((repo) => repo.selected).length },
    { label: "Proof PRs", value: sampleData.repos.filter((repo) => repo.selected).reduce((total, repo) => total + repo.prs, 0) },
    { label: "Receipts", value: sampleData.projects.reduce((total, project) => total + project.receipts, 0) },
    { label: "Release", value: "v2.1" },
  ];

  render(`
    <section class="section-pad" aria-labelledby="dashboard-title">
      <div class="section-heading compact">
        <span>Receipt Command Center</span>
        <h1 id="dashboard-title">Turn this week's work into proof.</h1>
        <p>Select repos, review evidence, and publish a clear receipt without exposing private work.</p>
      </div>
      <div class="dashboard-grid">
        <article class="release-card">
          <div>
            <span>Featured receipt</span>
            <h3>${sampleData.release.title}</h3>
            <p>${sampleData.release.summary} Review the release card before sharing it to your profile.</p>
            <div class="talent-tags">${tags(sampleData.release.signals)}</div>
          </div>
          <a class="secondary-action" href="${linkTo("receipt")}">Review</a>
        </article>
        <aside class="profile-card" aria-label="Next action">
          <div class="profile-header">
            <div class="avatar">${sampleData.builder.avatar}</div>
            <div>
              <h3>Next action</h3>
              <p>Confirm repo sources, then generate the share card.</p>
            </div>
            <span>Ready</span>
          </div>
          <p>${sampleData.repos.filter((repo) => repo.selected).length} repos are currently included in public proof for ${sampleData.builder.handle}.</p>
          <div class="hero-actions">
            <a class="primary-action" href="${linkTo("studio")}">Open studio</a>
            <a class="secondary-action" href="${linkTo("repos")}">Sources</a>
          </div>
        </aside>
      </div>
      ${statGrid(proofStats)}
      <div class="apps-grid">
        ${proofCard("Builder profile", "Check how the selected proof appears on your public builder profile.", "profile")}
        ${proofCard("Proof sources", "Choose which GitHub repos count toward public stats and receipts.", "repos")}
        ${proofCard("Receipt Studio", "Edit evidence, generate a card, and prepare the share link.", "studio")}
      </div>
    </section>
  `);
}

function renderRepos() {
  render(`
    <section class="section-pad" aria-labelledby="repos-title">
      <div class="section-heading compact">
        <span>Proof Sources</span>
        <h1 id="repos-title">Choose which repos count.</h1>
        <p>Included repos power receipts, profile stats, project history, and momentum boards.</p>
      </div>
      <aside class="profile-card" aria-label="Source panel">
        <div class="profile-header">
          <div class="avatar">${sampleData.builder.avatar}</div>
          <div>
            <h3>GitHub source panel</h3>
            <p>${sampleData.builder.handle} controls what becomes public proof.</p>
          </div>
          <span>${sampleData.repos.filter((repo) => repo.selected).length} active</span>
        </div>
        ${statGrid([
          { label: "Connected", value: sampleData.repos.length },
          { label: "Included", value: sampleData.repos.filter((repo) => repo.selected).length },
          { label: "Private", value: sampleData.repos.filter((repo) => repo.visibility === "private").length },
          { label: "Merged PRs", value: sampleData.repos.reduce((total, repo) => total + repo.prs, 0) },
        ])}
      </aside>
      <div class="leaderboard" aria-label="Repository proof sources">${sampleData.repos
        .map(
          (repo) => `
            <article class="leader-row">
              <div>
                <strong>${repo.name}</strong>
                <span>${repo.visibility} repo · ${repo.prs} merged PRs</span>
              </div>
              <span>${repo.selected ? "included" : "paused"}</span>
              <strong>${repo.prs} PRs</strong>
              <button class="secondary-action${repo.selected ? " active" : ""}" type="button" data-repo-toggle="${repo.name}">
                ${repo.selected ? "Included" : "Include"}
              </button>
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
        <span>Receipt Studio</span>
        <h1 id="studio-title">Edit the evidence. Generate the card.</h1>
        <p>Polish the receipt copy, choose what evidence appears, and prepare a share link.</p>
      </div>
      <div class="dashboard-grid">
        <article class="release-card" aria-label="Evidence panel">
          <div>
            <span>Evidence panel</span>
            <h3>${sampleData.release.title}</h3>
            <p>${sampleData.release.summary} Source repos: ${sampleData.repos
              .filter((repo) => repo.selected)
              .map((repo) => repo.name)
              .join(", ")}.</p>
            <div class="talent-tags">${tags(sampleData.release.signals)}</div>
          </div>
          <a class="secondary-action" href="${linkTo("repos")}">Sources</a>
        </article>
        <form class="profile-card" aria-label="Editor panel">
          <div class="profile-header">
            <div class="avatar">${sampleData.builder.avatar}</div>
            <div>
              <h3>Editor panel</h3>
              <p>Write the proof card that appears on your profile.</p>
            </div>
            <span>Draft</span>
          </div>
          <label>
            Receipt copy
            <textarea rows="6">${sampleData.release.title}: ${sampleData.release.summary}</textarea>
          </label>
          <label>
            <input type="checkbox" checked>
            Include selected repo names
          </label>
          <label>
            <input type="checkbox" checked>
            Include merged PR count
          </label>
        </form>
      </div>
      <article class="release-card share-output">
        <div>
          <span>Share output</span>
          <h3>${sampleData.builder.handle}/${sampleData.release.title.toLowerCase().replace(/\s+/g, "-")}</h3>
          <p>Generated card is ready for profile, project page, and outbound updates.</p>
        </div>
        <button class="primary-action" type="button" data-copy-link>Copy link</button>
      </article>
    </section>
  `);
}

function renderTrust() {
  render(`
    <section class="section-pad" aria-labelledby="trust-title">
      <div class="section-heading compact">
        <span>Trust Center</span>
        <h1 id="trust-title">Clear rules for GitHub proof.</h1>
        <p>PRBar turns selected GitHub activity into public proof while keeping private code and token usage out of the score.</p>
      </div>
      <div class="trust-grid">
        <article class="release-card">
          <div>
            <span>What PRBar reads</span>
            <h3>Selected GitHub metadata</h3>
            <p>Repository names, merged PR counts, release tags, timestamps, titles, and public proof fields chosen by the builder.</p>
          </div>
        </article>
        <article class="release-card">
          <div>
            <span>What PRBar counts</span>
            <h3>Shipping activity</h3>
            <p>Merged PRs, releases, project receipts, tests added, and recent momentum from repos the builder includes.</p>
          </div>
        </article>
        <article class="release-card">
          <div>
            <span>What PRBar protects</span>
            <h3>Private work stays private</h3>
            <p>Builders can pause repos, hide private source details, and decide which proof appears on public pages.</p>
          </div>
        </article>
        <article class="release-card">
          <div>
            <span>What PRBar does not count</span>
            <h3>No token scoreboard</h3>
            <p>Token usage, prompt volume, vanity commits, and unmerged work do not become proof of shipping.</p>
          </div>
        </article>
        <article class="release-card">
          <div>
            <span>Anti-gaming</span>
            <h3>Receipts need durable signals</h3>
            <p>Proof favors merged work, release history, project context, and source consistency over noisy activity spikes.</p>
          </div>
        </article>
      </div>
    </section>
  `);
}

function openModal() {
  modal.hidden = false;
}

if (hasAppShell) {
  window.addEventListener("hashchange", renderRoute);

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
