const routes = [
  { path: "/home", label: "Home" },
  { path: "/network", label: "Connect" },
  { path: "/boards", label: "Showcase" },
  { path: "/talent", label: "Talent" },
  { path: "/dashboard", label: "Dashboard" },
  { path: "/profile", label: "Profile" },
  { path: "/card", label: "Builder Card" },
  { path: "/receipt", label: "Receipt" },
  { path: "/project", label: "Project" },
  { path: "/repos", label: "Repos" },
  { path: "/studio", label: "Studio" },
  { path: "/trust", label: "Trust" },
];

const primaryNavPaths = ["/home", "/network", "/boards", "/talent", "/profile"];

const routeGroups = [
  {
    title: "Home",
    path: "/home",
    routes: [],
  },
  {
    title: "Connect",
    path: "/network",
    routes: [
      { path: "/network", label: "Feed" },
      { path: "/profile", label: "Builder Profile" },
      { path: "/receipt", label: "Receipt" },
    ],
  },
  {
    title: "Showcase",
    path: "/boards",
    routes: [
      { path: "/boards", label: "Apps" },
      { path: "/project", label: "App Page" },
      { path: "/receipt", label: "Receipt" },
    ],
  },
  {
    title: "Talent",
    path: "/talent",
    routes: [
      { path: "/talent", label: "Talent Board" },
      { path: "/profile", label: "Builder Profile" },
    ],
  },
  {
    title: "Profile",
    path: "/profile",
    routes: [
      { path: "/profile", label: "Public Profile" },
      { path: "/dashboard", label: "Dashboard" },
      { path: "/card", label: "Builder Card" },
      { path: "/repos", label: "GitHub Sources" },
      { path: "/studio", label: "Create Receipt" },
      { path: "/trust", label: "Trust" },
    ],
  },
];

const builders = [
  {
    name: "Maya Chen",
    handle: "@maya.codes",
    initials: "MC",
    title: "AI-native mobile and micro-SaaS builder",
    location: "Phoenix, AZ",
    availability: "Open to launch sprints",
    tools: ["Claude Code", "Cursor", "Xcode", "Vercel"],
    domains: ["iOS", "Micro-SaaS", "AI search"],
    stats: { prs: 42, releases: 4, streak: 9, repos: 6 },
    proof: "4 releases in 7 days, 42 merged PRs, 2 public projects moved from prototype to shipped.",
    receipt: "SideProject Radar v2.1",
    repo: "maya/sideproject-radar",
    tag: "v2.1.0",
    prList: ["#184", "#188", "#191"],
    trend: [42, 58, 51, 73, 88, 96],
  },
  {
    name: "Nora Patel",
    handle: "@nora.ship",
    initials: "NP",
    title: "SaaS dashboard builder for founder-led teams",
    location: "Remote, US",
    availability: "Available this month",
    tools: ["Cursor", "Supabase", "Stripe", "Next.js"],
    domains: ["SaaS", "Billing", "Launch"],
    stats: { prs: 31, releases: 3, streak: 6, repos: 4 },
    proof: "Published a launch kit, shipped billing analytics, and closed 11 linked PRs.",
    receipt: "Launch Sprint Kit",
    repo: "nora/launch-sprint-kit",
    tag: "v0.9.4",
    prList: ["#72", "#74", "#80"],
    trend: [31, 36, 40, 62, 59, 71],
  },
  {
    name: "Devon Reyes",
    handle: "@devon.codes",
    initials: "DR",
    title: "iOS product engineer using agentic workflows",
    location: "Seattle, WA",
    availability: "Selective advisory",
    tools: ["Claude Code", "SwiftUI", "GitHub Actions"],
    domains: ["Mobile", "Devtools", "AI UX"],
    stats: { prs: 24, releases: 2, streak: 11, repos: 3 },
    proof: "Turned a private beta into a shareable iOS receipt flow across 2 app releases.",
    receipt: "iOS Proof Cards",
    repo: "devon/proof-cards-ios",
    tag: "v1.3.0",
    prList: ["#57", "#61", "#63"],
    trend: [22, 28, 35, 39, 46, 52],
  },
];

const releases = [
  {
    title: "SideProject Radar v2.1",
    builder: builders[0],
    project: "SideProject Radar",
    source: "Imported from GitHub Releases",
    date: "May 26, 2026",
    summary: "Discovery filters, release-note import, and scoring tests shipped from 8 merged PRs.",
    facts: ["8 PRs merged", "2 repos selected", "v2.1.0 tagged", "34 tests added"],
  },
  {
    title: "Launch Sprint Kit v0.9",
    builder: builders[1],
    project: "Launch Sprint Kit",
    source: "Imported from GitHub Releases",
    date: "May 25, 2026",
    summary: "Stripe metrics, onboarding checklist, and founder handoff docs released in one sprint.",
    facts: ["11 PRs merged", "1 repo selected", "v0.9.4 tagged", "docs included"],
  },
  {
    title: "iOS Proof Cards v1.3",
    builder: builders[2],
    project: "iOS Proof Cards",
    source: "Imported from GitHub Releases",
    date: "May 24, 2026",
    summary: "Share-card rendering, private repo redaction, and release receipt previews landed.",
    facts: ["6 PRs merged", "2 releases", "SwiftUI", "CI passed"],
  },
];

const showcaseApps = [
  {
    name: "SideProject Radar",
    builder: builders[0],
    status: "Public beta",
    category: "AI discovery",
    tagline: "A weekly radar for indie products before they trend.",
    description: "Maya connects two selected repos, release notes, and app screenshots so people can inspect the product and the proof behind it.",
    links: ["Web app", "GitHub", "Receipt"],
    proof: ["42 PRs", "4 releases", "v2.1.0", "9-day streak"],
    repos: ["maya/sideproject-radar", "maya/radar-ios"],
    receipt: releases[0],
    score: "128 votes",
    pick: "PRBar pick",
    color: "#19b394",
  },
  {
    name: "Launch Sprint Kit",
    builder: builders[1],
    status: "Founder-ready",
    category: "Micro-SaaS",
    tagline: "Billing, onboarding, and launch handoff patterns for fast SaaS teams.",
    description: "A curated app page lets Nora show the thing she built, then back it with the release trail imported from GitHub.",
    links: ["Demo", "Docs", "Receipt"],
    proof: ["31 PRs", "3 releases", "Stripe", "6-day streak"],
    repos: ["nora/launch-sprint-kit"],
    receipt: releases[1],
    score: "97 votes",
    pick: "Community",
    color: "#f4c430",
  },
  {
    name: "iOS Proof Cards",
    builder: builders[2],
    status: "App Store build",
    category: "Devtools",
    tagline: "Native share cards for builders who want receipts instead of claims.",
    description: "Devon can show the iOS app, attach the public package and private app repo, and keep client-sensitive proof redacted.",
    links: ["App Store", "TestFlight", "Receipt"],
    proof: ["24 PRs", "2 releases", "SwiftUI", "11-day streak"],
    repos: ["devon/proof-cards-ios", "devon/proof-card-renderer"],
    receipt: releases[2],
    score: "84 votes",
    pick: "Rising",
    color: "#2f6fed",
  },
];

const networkPosts = releases.map((release, index) => ({
  release,
  action: ["shipped a release", "published a launch receipt", "tagged a proof milestone"][index],
  note: [
    "Seven-day sprint: discovery filters, imported release notes, and scoring tests moved from PR stack to public release.",
    "A founder-ready launch kit landed with billing metrics, onboarding checklists, and a cleaner handoff path.",
    "The iOS receipt flow now supports private repo redaction and native share previews from selected sources.",
  ][index],
  ask: ["View proof resume", "Open proof profile", "Inspect proof profile"][index],
}));

const repoSources = [
  { name: "maya/sideproject-radar", visibility: "public", status: "included", lastRelease: "v2.1.0", activity: "18 PRs in 14 days" },
  { name: "maya/radar-ios", visibility: "private", status: "included", lastRelease: "v1.4.1", activity: "9 PRs in 14 days" },
  { name: "client/stealth-onboarding", visibility: "private", status: "redacted", lastRelease: "hidden", activity: "5 PRs counted" },
  { name: "maya/experiments", visibility: "public", status: "excluded", lastRelease: "none", activity: "prototype only" },
];

const timeline = [
  { date: "May 26", title: "SideProject Radar v2.1", detail: "8 PRs merged, release notes imported, scoring tests added." },
  { date: "May 21", title: "Discovery filters", detail: "Search filters and saved list UI landed across 3 linked PRs." },
  { date: "May 17", title: "Radar scoring beta", detail: "First public receipt generated from selected repo activity." },
];

const boardViews = {
  apps: {
    label: "Apps",
    eyebrow: "App showcase",
    description: "Discover what AI-native builders are making, with GitHub proof behind every product.",
    items: showcaseApps,
  },
  builders: {
    label: "Builders",
    eyebrow: "Builder momentum",
    description: "Follow people whose apps, releases, and merged PRs show real velocity.",
    items: showcaseApps,
  },
  receipts: {
    label: "Receipts",
    eyebrow: "Fresh proof",
    description: "Browse the release receipts behind the apps and builders getting attention.",
    items: showcaseApps,
  },
};

const boardFilters = ["This week", "AI apps", "iOS", "SaaS", "Devtools", "Public beta", "Hiring signal"];

const boardPicks = [
  { label: "PRBar Pick", title: "SideProject Radar", copy: "Best product page this week: real app, selected repos, release notes, and visible cadence." },
  { label: "Community Nominee", title: "Launch Sprint Kit", copy: "Founders keep saving this because the product story is easy to inspect." },
  { label: "Needs votes", title: "iOS Proof Cards", copy: "Strong native proof surface, currently climbing in Mobile + Devtools." },
];

const magicSteps = [
  {
    step: "01",
    title: "Claim your card",
    copy: "Reserve a compact proof link you can use in bios, resumes, intros, and launch posts.",
    path: "/card",
  },
  {
    step: "02",
    title: "Connect GitHub",
    copy: "Import release tags, merged PRs, checks, and repo activity from the sources you approve.",
    path: "/dashboard",
  },
  {
    step: "03",
    title: "Choose what counts",
    copy: "Pick the repos and apps that count, redact private work, and leave experiments out of the public story.",
    path: "/repos",
  },
  {
    step: "04",
    title: "Publish proof resume",
    copy: "Turn selected repos, apps, releases, and receipts into a proof profile you can share anywhere.",
    path: "/profile",
  },
];

const app = document.querySelector("#app");
let lastRenderedPath = null;

if ("scrollRestoration" in window.history) {
  window.history.scrollRestoration = "manual";
}

function routePath() {
  const path = window.location.hash.replace("#", "") || "/home";
  return routes.some((route) => route.path === path) ? path : "/home";
}

function setRoute(path) {
  window.location.hash = path;
}

function routeBelongsToGroup(path, group) {
  return group.path === path || group.routes.some((route) => route.path === path);
}

function canonicalSectionFor(path) {
  return routeGroups.find((group) => group.path === path)?.path
    || routeGroups.find((group) => routeBelongsToGroup(path, group))?.path
    || "/home";
}

function readActiveSection(path) {
  try {
    const stored = window.sessionStorage?.getItem("prbar-active-section");
    const group = routeGroups.find((item) => item.path === stored);
    if (group && routeBelongsToGroup(path, group)) return group.path;
  } catch {
    // Fall through to the canonical section when browser storage is unavailable.
  }

  return canonicalSectionFor(path);
}

function writeActiveSection(sectionPath) {
  try {
    window.sessionStorage?.setItem("prbar-active-section", sectionPath);
  } catch {
    // Context is optional; direct routes still use canonical sections.
  }
}

function readTocCollapsed() {
  try {
    return window.localStorage?.getItem("prbar-toc-collapsed") === "true";
  } catch {
    return false;
  }
}

function writeTocCollapsed(collapsed) {
  try {
    window.localStorage?.setItem("prbar-toc-collapsed", String(collapsed));
  } catch {
    // The mockup still works if browser storage is unavailable.
  }
}

function shell(content) {
  const path = routePath();
  const activeSection = readActiveSection(path);
  return `
    <div class="mockup-shell">
      ${tableOfContents(path, activeSection)}
      <div class="mockup-main">
        <header class="topbar">
          <button class="toc-toggle" type="button" aria-label="Hide table of contents" aria-pressed="false" data-toc-toggle>
            <span class="panel-icon" aria-hidden="true"><i></i><b></b></span>
          </button>
          <a class="brand" href="#/home" aria-label="PRBar home"><span>PR</span><strong>PRBar</strong></a>
          <nav class="nav" aria-label="Primary navigation">
            ${routes.filter((route) => primaryNavPaths.includes(route.path)).map((route) => `<a class="${activeSection === route.path ? "active" : ""}" data-section="${route.path}" href="#${route.path}">${route.label}</a>`).join("")}
          </nav>
          <a class="topbar-action" href="#/dashboard">Claim profile</a>
        </header>
        <main>${content}</main>
      </div>
    </div>
  `;
}

function tableOfContents(path, activeSection) {
  return `
    <aside class="toc-sidebar" aria-label="Mockup table of contents">
      <div class="toc-brand">
        <a class="brand" href="#/home" aria-label="PRBar home"><span>PR</span><strong>PRBar</strong></a>
        <p>Mockup tree</p>
      </div>
      <nav class="toc-nav">
        <div class="toc-root"><span>PRBar Web</span></div>
        ${routeGroups.map((group, groupIndex) => `
          <section class="tree-group">
            <a class="tree-parent ${activeSection === group.path ? "active" : ""}" data-section="${group.path}" href="#${group.path}">
              <span>${String(groupIndex + 1).padStart(2, "0")}</span>
              <strong>${group.title}</strong>
            </a>
            <div class="tree-children">
              ${group.routes.map((route) => `
                <a class="${activeSection === group.path && path === route.path ? "active" : ""}" data-section="${group.path}" href="#${route.path}">
                  <span>
                    <strong>${route.label}</strong>
                  </span>
                </a>
              `).join("")}
            </div>
          </section>
        `).join("")}
      </nav>
    </aside>
  `;
}

function routeIndex() {
  return `
    <details class="route-index" aria-label="Mockup page index">
      <summary>
        <span>Mockup review map</span>
        <b>Open all pages</b>
      </summary>
      <div class="route-index-groups">
        ${routeGroups.map((group) => `
          <article>
            <h3>${group.title}</h3>
            <div class="route-link-list">
              ${group.routes.map((route) => `
                <a href="#${route.path}"><strong>${route.label}</strong></a>
              `).join("")}
            </div>
          </article>
        `).join("")}
      </div>
    </details>
  `;
}

function statPills(items) {
  return `<div class="stat-pills">${items.map((item) => `<span>${item}</span>`).join("")}</div>`;
}

function publishJourney(activeIndex = 0, options = {}) {
  return `
    <section class="journey-strip ${options.compact ? "compact" : ""}" aria-label="Proof resume workflow">
      <div class="journey-heading">
        <p class="eyebrow">First magic moment</p>
        <h2>${options.title || "Turn a week of GitHub work into proof people can inspect."}</h2>
        <p>${options.copy || "The private flow starts with sources and ends with public receipts attached to your builder profile and apps."}</p>
      </div>
      <div class="journey-steps">
        ${magicSteps.map((item, index) => `
          <a class="${index === activeIndex ? "active" : ""}" href="#${item.path}">
            <span>${item.step}</span>
            <strong>${item.title}</strong>
            <small>${item.copy}</small>
          </a>
        `).join("")}
      </div>
    </section>
  `;
}

function sparkline(values) {
  return `
    <div class="sparkline" aria-hidden="true">
      ${values.map((value) => `<span style="height: ${value}%"></span>`).join("")}
    </div>
  `;
}

function receiptCard(release, options = {}) {
  return `
    <article class="receipt-card ${options.compact ? "compact" : ""}">
      <div class="receipt-top">
        <span>${release.source}</span>
        <b>${release.date}</b>
      </div>
      <h3>${release.title}</h3>
      <p>${release.summary}</p>
      ${statPills(release.facts)}
      <div class="source-row">
        <code>${release.builder.repo}</code>
        <a href="#/receipt">Inspect receipt</a>
      </div>
    </article>
  `;
}

function proofChain(items = ["GitHub release", "Merged PRs", "Builder context", "Public receipt"]) {
  return `
    <div class="proof-chain" aria-label="Proof chain">
      ${items.map((item, index) => `
        <span>
          <b>${String(index + 1).padStart(2, "0")}</b>
          ${item}
        </span>
      `).join("")}
    </div>
  `;
}

function builderLinkCard(options = {}) {
  const builder = builders[0];
  const cardId = options.id || `builder-card-${Math.random().toString(36).slice(2)}`;
  return `
    <div class="builder-link-card-wrap ${options.compact ? "compact" : ""}" data-builder-link-card id="${cardId}">
      <div class="builder-link-stage">
        <div class="builder-link-ghost"></div>
        <div class="builder-link-ghost second"></div>
        <div class="builder-link-flip" data-card-flip>
          <section class="builder-link-face builder-link-front">
            <span class="builder-link-glare" aria-hidden="true"></span>
            <div class="builder-link-identity">
              <div>
                <span>${builder.handle}</span>
                <h3>${builder.name}</h3>
              </div>
              <div class="avatar">${builder.initials}</div>
            </div>
            <p>AI-native mobile and micro-SaaS builder. This week’s proof from selected GitHub repos.</p>
            <div class="builder-link-chart" aria-label="PR distribution by day">
              <i style="height:34%"></i><i style="height:58%"></i><i style="height:42%"></i><i style="height:76%"></i><i style="height:64%"></i><i style="height:100%"></i><i style="height:82%"></i>
            </div>
            <div class="builder-link-stats">
              <div><b>${builder.stats.prs}</b><span>merged PRs</span></div>
              <div><b>${builder.stats.repos}</b><span>active repos</span></div>
              <div><b>${builder.stats.streak}</b><span>day streak</span></div>
            </div>
            <small>Front: PR distribution</small>
          </section>
          <section class="builder-link-face builder-link-back">
            <span class="builder-link-glare" aria-hidden="true"></span>
            <div class="builder-link-identity">
              <div>
                <span>Proof links</span>
                <h3>Receipts and apps</h3>
              </div>
              <div class="avatar">${builder.initials}</div>
            </div>
            <p>The back keeps the linktree job: inspect releases, open apps, or jump to the full proof profile.</p>
            <div class="builder-link-tabs" role="tablist" aria-label="Builder card back tabs">
              <button class="active" type="button" role="tab" aria-selected="true" data-link-card-tab="releases">Releases</button>
              <button type="button" role="tab" aria-selected="false" data-link-card-tab="apps">Apps</button>
            </div>
            <div class="builder-link-list active" data-link-card-panel="releases">
              ${releases.map((release) => `
                <a href="#/receipt">
                  <span><strong>${release.title}</strong><em>${release.facts.slice(0, 2).join(" · ")}</em></span>
                  <b>View</b>
                </a>
              `).join("")}
            </div>
            <div class="builder-link-list" data-link-card-panel="apps">
              ${showcaseApps.slice(0, 2).map((item) => `
                <a href="#/project">
                  <span><strong>${item.name}</strong><em>${item.status} · latest receipt</em></span>
                  <b>Open</b>
                </a>
              `).join("")}
              <a href="#/profile">
                <span><strong>Maya’s proof profile</strong><em>Receipts, apps, timeline</em></span>
                <b>View</b>
              </a>
            </div>
            <small>Back: Releases / Apps</small>
          </section>
        </div>
      </div>
      <div class="builder-link-controls" aria-label="Builder card controls">
        <button class="active" type="button" data-card-side="front">Front: PRs</button>
        <button type="button" data-card-side="back">Back: Links</button>
      </div>
    </div>
  `;
}

function builderCard(builder, options = {}) {
  return `
    <article class="builder-card ${options.featured ? "featured" : ""}">
      <div class="identity-row">
        <span class="avatar">${builder.initials}</span>
        <div>
          <h3>${builder.handle}</h3>
          <p>${builder.title}</p>
        </div>
        <b>${builder.availability}</b>
      </div>
      <p>${builder.proof}</p>
      <div class="metric-strip">
        <span><strong>${builder.stats.prs}</strong> PRs</span>
        <span><strong>${builder.stats.releases}</strong> releases</span>
        <span><strong>${builder.stats.streak}</strong> day streak</span>
      </div>
      ${sparkline(builder.trend)}
      <div class="tag-row">${builder.tools.map((tool) => `<span>${tool}</span>`).join("")}</div>
    </article>
  `;
}

function appPreview(app) {
  return `
    <div class="app-preview" style="--app-color: ${app.color}">
      <div class="app-window">
        <span></span><span></span><span></span>
      </div>
      <div class="app-preview-body">
        <strong>${app.name}</strong>
        <p>${app.tagline}</p>
        <div class="app-preview-bars">
          ${app.builder.trend.map((value) => `<i style="height: ${value}%"></i>`).join("")}
        </div>
      </div>
    </div>
  `;
}

function showcaseAppCard(app, index) {
  return `
    <article class="app-showcase-card">
      <div class="rank">
        <span>#${index + 1}</span>
        <button type="button" aria-label="Vote for ${app.name}">▲</button>
      </div>
      <div class="app-card-body">
        ${appPreview(app)}
        <div class="app-card-copy">
          <div class="identity-row compact">
            <span class="avatar">${app.builder.initials}</span>
            <div>
              <h3>${app.name}</h3>
              <p>${app.builder.handle} · ${app.category} · ${app.status}</p>
            </div>
            <b>${app.pick}</b>
          </div>
          <p>${app.description}</p>
          <div class="board-proof-row">
            ${app.proof.map((item) => `<span>${item}</span>`).join("")}
          </div>
          <div class="app-links">
            ${app.links.map((link) => `<a href="${link === "Receipt" ? "#/receipt" : "#/project"}">${link}</a>`).join("")}
          </div>
          <div class="source-row">
            <code>${app.repos.join(" + ")}</code>
            <div class="board-actions">
              <span>${app.score}</span>
              <a href="#/receipt">Receipts behind rank</a>
            </div>
          </div>
        </div>
      </div>
    </article>
  `;
}

function miniProofHistogram() {
  return `
    <div class="mini-proof-histogram" aria-label="PR distribution by day">
      <i style="height: 34%"></i>
      <i style="height: 58%"></i>
      <i style="height: 42%"></i>
      <i style="height: 76%"></i>
      <i style="height: 64%"></i>
      <i style="height: 100%"></i>
      <i style="height: 82%"></i>
    </div>
  `;
}

function networkPost(post) {
  const { release } = post;
  return `
    <article class="network-post">
      <div class="post-actor">
        <span class="avatar">${release.builder.initials}</span>
        <div>
          <h2>${release.builder.handle} ${post.action}</h2>
          <p>${release.project} · ${release.date} · ${release.builder.domains.join(" / ")}</p>
        </div>
        <a href="#/profile">View proof</a>
      </div>
      <p class="post-note">${post.note}</p>
      <div class="post-proof">
        <div>
          <span>Receipt</span>
          <h3>${release.title}</h3>
          ${statPills(release.facts)}
        </div>
        ${miniProofHistogram()}
      </div>
      <div class="source-row">
        <code>${release.builder.repo} ${release.builder.tag}</code>
        <div class="post-actions">
          <a href="#/receipt">Inspect receipt</a>
          <a href="#/project">View project</a>
          <a href="#/talent">${post.ask}</a>
        </div>
      </div>
    </article>
  `;
}

function homePage() {
  return shell(`
    <section class="hero">
      <div class="hero-copy">
        <p class="eyebrow">The resume for AI-native builders</p>
        <h1>Resumes are garbage.</h1>
        <p class="lede">Your real resume is what you ship.</p>
        <p class="hero-proof-line">PRBar turns your PRs, releases, app updates, and shipped features into a living proof profile you can share anywhere.</p>
        <div class="action-row">
          <a class="primary" href="#/card">Claim your card</a>
          <a class="secondary" href="#/profile">View proof profile</a>
        </div>
      </div>
      <div class="hero-proof">
        ${builderLinkCard({ id: "home-builder-card" })}
      </div>
    </section>
    ${publishJourney(0, {
      title: "Claim your card. Connect GitHub. Publish your proof resume.",
      copy: "Start with the builder card, choose what counts, then turn selected repos, apps, and releases into a profile you can share anywhere."
    })}
    <section class="proof-manifesto">
      <p>No feed. No threads. No productivity theater. Just proof.</p>
    </section>
    <section class="surface-grid">
      <a class="surface-card" href="#/card"><span>01</span><h2>Builder Card</h2><p>Your compact proof link for bios, resumes, and intros.</p></a>
      <a class="surface-card" href="#/profile"><span>02</span><h2>Proof Resume</h2><p>A living profile built from PRs, releases, apps, and shipped features.</p></a>
      <a class="surface-card" href="#/boards"><span>03</span><h2>App Showcase</h2><p>Simple project pages with the receipts behind the work.</p></a>
    </section>
    ${routeIndex()}
  `);
}

function networkPage() {
  return shell(`
    <section class="page-hero">
      <p class="eyebrow">Connect</p>
      <h1>Follow proof, not posts.</h1>
      <p>Track builders by releases, app updates, and shipped work. No threads required.</p>
      <div class="network-tabs" aria-label="Connect filters">
        <button class="active" type="button">Receipts</button>
        <button type="button">Builders</button>
        <button type="button">Projects</button>
        <button type="button">Apps</button>
      </div>
    </section>
    <section class="network-layout">
      <div class="feed">
        ${networkPosts.map((post) => networkPost(post)).join("")}
      </div>
      <aside class="side-panel">
        <div class="network-brief">
          <span>Connect signal</span>
          <h2>Work is the surface.</h2>
          <p>Open the receipt, inspect the app, or view the proof resume behind each shipped thing.</p>
        </div>
        ${builderCard(builders[0], { featured: true })}
        <div class="proof-rule">
          <h2>What counts here</h2>
          <p>PRs merged, releases tagged, tests added, projects launched, and source-linked receipts.</p>
          ${statPills(["GitHub source", "Release tags", "Repo selection", "Private redaction"])}
        </div>
      </aside>
    </section>
  `);
}

function boardsPage(activeView = "apps") {
  const view = boardViews[activeView] || boardViews.apps;
  const featured = view.items[0];
  return shell(`
    <section class="page-hero dark">
      <p class="eyebrow">${view.eyebrow}</p>
      <h1>Apps with receipts.</h1>
      <p>Browse projects backed by releases, PRs, and app updates.</p>
      ${proofChain(["Builder publishes proof", "App gets attached", "Community votes", "PRBar can feature it"])}
      <div class="board-filterbar" aria-label="Showcase filters">
        ${boardFilters.map((filter, index) => `<button class="${index === 0 ? "active" : ""}" type="button">${filter}</button>`).join("")}
      </div>
      <div class="board-tabs" role="tablist" aria-label="Showcase views">
        ${Object.entries(boardViews).map(([key, item]) => `<button class="${key === activeView ? "active" : ""}" data-board="${key}" type="button">${item.label}</button>`).join("")}
      </div>
    </section>
    <section class="board-discovery">
      <article class="board-spotlight">
        <span>${featured.pick} · Featured app</span>
        <h2>${featured.name}</h2>
        <p>${featured.tagline}</p>
        ${appPreview(featured)}
        <div class="spotlight-reason">
          <b>Why featured</b>
          <span>${featured.description}</span>
        </div>
        <div class="spotlight-grid">
          <div><strong>${featured.builder.stats.prs}</strong><span>merged PRs</span></div>
          <div><strong>${featured.builder.stats.releases}</strong><span>releases</span></div>
          <div><strong>${featured.score}</strong><span>showcase signal</span></div>
        </div>
        ${sparkline(featured.builder.trend)}
        <div class="app-links spotlight-links">
          <a href="#/project">Open app page</a>
          <a href="#/receipt">View receipt</a>
          <a href="#/profile">View proof resume</a>
        </div>
      </article>
      <div class="board-main">
        <div class="board-list">
          ${view.items.map((item, index) => showcaseAppCard(item, index)).join("")}
        </div>
        <aside class="board-rail">
          <h2>How apps make the board</h2>
          <article>
            <span>User curated</span>
            <h3>Add the product GitHub cannot see</h3>
            <p>Builders can add app links, screenshots, status, and context, then attach the repos and receipts that prove the work.</p>
          </article>
          ${boardPicks.map((pick) => `
            <article>
              <span>${pick.label}</span>
              <h3>${pick.title}</h3>
              <p>${pick.copy}</p>
            </article>
          `).join("")}
        </aside>
      </div>
    </section>
  `);
}

function talentPage(filter = "all") {
  const filtered = filter === "all" ? builders : builders.filter((builder) => builder.domains.map((item) => item.toLowerCase()).includes(filter));
  return shell(`
    <section class="page-hero">
      <p class="eyebrow">Talent Board</p>
      <h1>Find builders by what they shipped.</h1>
      <p>Search proof resumes, not polished claims.</p>
      ${proofChain(["Recent receipts", "Relevant stack", "App outcomes", "Availability"])}
      <div class="search-prompt">I need someone to ship: <strong>iOS MVP / SaaS onboarding / AI agent UI</strong></div>
      <div class="board-tabs talent-tabs" aria-label="Talent filters">
        ${["all", "ios", "saas", "launch"].map((key) => `<button class="${key === filter ? "active" : ""}" data-filter="${key}" type="button">${key}</button>`).join("")}
      </div>
    </section>
    <section class="talent-grid">
      ${filtered.map((builder) => `
        <article class="talent-card">
          ${builderCard(builder)}
          <div class="talent-decision">
            <span><b>Best for</b>${builder.domains.join(", ")}</span>
            <span><b>Last shipped</b>${builder.receipt}</span>
            <span><b>Location</b>${builder.location}</span>
          </div>
          <div class="action-row small">
            <a class="primary" href="#/profile">View profile</a>
            <a class="secondary light" href="#/receipt">Latest receipt</a>
          </div>
        </article>
      `).join("")}
    </section>
  `);
}

function dashboardPage() {
  return shell(`
    <section class="page-hero">
      <p class="eyebrow">Private dashboard</p>
      <h1>Choose what counts.</h1>
      <p>Connect GitHub, pick your repos and apps, then publish a proof resume you can share anywhere.</p>
    </section>
    ${publishJourney(1, {
      compact: true,
      title: "Your proof resume starts with selected sources.",
      copy: "PRBar has the facts. You choose the repos, app links, and releases that belong on the public surface."
    })}
    <section class="workflow-layout">
      <article class="command-panel">
        <div class="panel-heading"><span>Next action</span><h2>Publish SideProject Radar v2.1</h2></div>
        <ol class="checklist">
          <li class="done"><b>GitHub connected</b><span>@maya.codes synced 11 minutes ago</span></li>
          <li class="done"><b>Repos selected</b><span>2 public, 2 private with redaction enabled</span></li>
          <li><b>Create builder card</b><span>Start with PR distribution, releases, and app links in one shareable object</span></li>
          <li><b>Publish profile and receipts</b><span>Preview profile, board eligibility, and receipt links</span></li>
        </ol>
        <div class="action-row small"><a class="primary" href="#/card">Build card</a><a class="secondary light" href="#/repos">Manage sources</a></div>
      </article>
      <div class="dashboard-stack">
        <article class="card-ready-panel">
          <div class="panel-heading"><span>First shareable asset</span><h2>Your builder card is ready.</h2></div>
          <p>Use it as a bio link, email signature, recruiting proof, launch post, or compact preview of the full profile.</p>
          <div class="action-row small"><a class="primary" href="#/card">Customize card</a><a class="secondary light" href="#/profile">View profile</a></div>
        </article>
        <article class="app-builder-panel">
          <div class="panel-heading"><span>New surface</span><h2>Add what GitHub cannot see</h2></div>
          <p>Show the app, product, TestFlight build, demo, or customer-facing thing your receipts helped ship.</p>
          <div class="app-form-preview">
            <label>App name<span>SideProject Radar</span></label>
            <label>Status<span>Public beta</span></label>
            <label>Links<span>Web app · GitHub · latest receipt</span></label>
            <label>Receipts attached<span>v2.1.0 · 8 PRs merged · 34 tests added</span></label>
          </div>
          <div class="action-row small"><a class="primary" href="#/project">Preview app page</a><a class="secondary light" href="#/repos">Attach repos</a></div>
        </article>
        ${receiptCard(releases[0])}
        <div class="mini-grid">
          <div><strong>68</strong><span>proof PRs</span></div>
          <div><strong>13</strong><span>receipts</span></div>
          <div><strong>4</strong><span>repos counted</span></div>
        </div>
      </div>
    </section>
  `);
}

function profilePage() {
  const builder = builders[0];
  return shell(`
    <section class="profile-hero">
      <div class="profile-main">
        <span class="avatar xl">${builder.initials}</span>
        <div>
          <p class="eyebrow">Proof Resume</p>
          <h1>PRBar is the resume for AI-native builders.</h1>
          <p>A living profile built from what ${builder.handle} actually shipped: selected repos, releases, app updates, and public receipts.</p>
          ${proofChain(["Selected repos", "Released apps", "Merged PRs", "Public receipts"])}
          <div class="action-row small"><a class="primary" href="#/receipt">Featured receipt</a><a class="secondary light" href="#/card">Customize card</a></div>
        </div>
      </div>
      <aside class="profile-aside">
        <b>${builder.availability}</b>
        ${statPills([...builder.tools, ...builder.domains])}
      </aside>
    </section>
    <section class="profile-proof-grid">
      <article class="profile-card-panel">
        <div class="panel-heading"><span>Portable proof</span><h2>Builder card</h2></div>
        ${builderLinkCard({ id: "profile-builder-card", compact: true })}
        <div class="action-row small"><a class="primary" href="#/card">Customize card</a></div>
      </article>
      ${builderCard(builder, { featured: true })}
      <div class="featured-apps-panel">
        <h2>Featured apps</h2>
        ${showcaseApps.slice(0, 2).map((item) => `
          <article>
            ${appPreview(item)}
            <div>
              <span>${item.status}</span>
              <h3>${item.name}</h3>
              <p>${item.tagline}</p>
              ${statPills(item.proof.slice(0, 3))}
            </div>
          </article>
        `).join("")}
      </div>
      <div class="timeline-panel">
        <h2>Proof timeline</h2>
        ${timeline.map((item) => `<article><span>${item.date}</span><h3>${item.title}</h3><p>${item.detail}</p></article>`).join("")}
      </div>
      ${receiptCard(releases[0])}
    </section>
  `);
}

function receiptPage() {
  const release = releases[0];
  const attachedApp = showcaseApps[0];
  return shell(`
    <section class="receipt-hero">
      <div>
        <p class="eyebrow">Release receipt</p>
        <h1>${release.title}</h1>
        <p>${release.summary}</p>
        ${statPills(release.facts)}
        ${proofChain(["Release tag v2.1.0", "8 merged PRs", "34 tests added", "Public app proof"])}
      </div>
      <aside>
        <span>Verified source</span>
        <code>${release.builder.repo}</code>
        <code>${release.builder.tag}</code>
        <b>${release.date}</b>
      </aside>
    </section>
    <section class="receipt-detail-grid">
      <article class="evidence-panel">
        <h2>Imported GitHub facts</h2>
        <div class="pr-list">
          ${release.builder.prList.map((pr, index) => `<div><b>${pr}</b><span>${["Discovery filters merged", "Release notes imported", "Scoring tests added"][index]}</span><em>Merged</em></div>`).join("")}
        </div>
      </article>
      <article class="annotation-panel">
        <h2>Builder annotation</h2>
        <p>This release moved the project from useful prototype to something people can revisit weekly. The receipt keeps the facts tied to GitHub while leaving room to explain the product decision.</p>
        <div class="action-row small"><a class="primary" href="#/studio">Edit in studio</a><a class="secondary light" href="#/project">View project</a></div>
      </article>
      <article class="receipt-app-panel">
        ${appPreview(attachedApp)}
        <div>
          <span>This receipt supports</span>
          <h2>${attachedApp.name}</h2>
          <p>${attachedApp.description}</p>
          ${statPills(attachedApp.proof)}
        </div>
      </article>
    </section>
  `);
}

function projectPage() {
  const item = showcaseApps[0];
  return shell(`
    <section class="project-hero">
      <p class="eyebrow">${item.status} · ${item.category}</p>
      <h1>${item.name}</h1>
      <p>${item.description}</p>
      ${proofChain(["App added by builder", "Repos attached", "Latest receipt published", "Eligible for Showcase"])}
      <div class="project-links"><a href="#/receipt">Latest receipt</a><a href="#/profile">Builder profile</a><a href="#/repos">Source repos</a></div>
    </section>
    <section class="project-grid">
      <article class="project-visual"><span>Live app page</span><strong>${item.tagline}</strong>${appPreview(item)}${statPills(item.proof)}</article>
      <article class="proof-trail-panel">
        <h2>Proof trail</h2>
        <p>This is the part GitHub cannot assemble on its own: the app, status, launch links, selected repos, and latest receipt in one inspectable page.</p>
        ${receiptCard(item.receipt, { compact: true })}
      </article>
      <div class="timeline-panel">
        <h2>What changed over time</h2>
        ${timeline.map((item) => `<article><span>${item.date}</span><h3>${item.title}</h3><p>${item.detail}</p></article>`).join("")}
      </div>
    </section>
  `);
}

function reposPage() {
  const repoApps = [
    { repos: "maya/sideproject-radar + maya/radar-ios", app: "SideProject Radar", mode: "Public app page" },
    { repos: "nora/launch-sprint-kit", app: "Launch Sprint Kit", mode: "Demo + docs" },
    { repos: "client/stealth-onboarding", app: "Private client app", mode: "Counts only, names hidden" },
  ];

  return shell(`
    <section class="page-hero">
      <p class="eyebrow">GitHub Sources</p>
      <h1>Choose which repos count.</h1>
      <p>Control profiles, boards, receipts, and private redaction from one source list.</p>
    </section>
    ${publishJourney(2, {
      compact: true,
      title: "Select the inputs before anything goes public.",
      copy: "Sources are the control layer: include product repos, attach them to apps, and redact private work before receipts are published."
    })}
    <section class="repo-layout">
      <aside class="source-summary">
        <h2>@maya.codes</h2>
        <div class="mini-grid">
          <div><strong>4</strong><span>available repos</span></div>
          <div><strong>3</strong><span>counted</span></div>
        </div>
        <p>Private names can stay hidden while merged PR counts and release receipts remain eligible.</p>
      </aside>
      <div class="repo-list">
        <article class="repo-attach-panel">
          <h2>Attach repos to apps</h2>
          <p>Receipts can power a public product page, a private proof trail, or both.</p>
          ${repoApps.map((item) => `
            <div>
              <code>${item.repos}</code>
              <span>${item.app}</span>
              <b>${item.mode}</b>
            </div>
          `).join("")}
        </article>
        ${repoSources.map((repo) => `
          <article class="repo-row">
            <div><h3>${repo.name}</h3><p>${repo.activity} / latest release ${repo.lastRelease}</p></div>
            <span>${repo.visibility}</span>
            <b>${repo.status}</b>
          </article>
        `).join("")}
      </div>
    </section>
  `);
}

function studioPage() {
  return shell(`
    <section class="page-hero">
      <p class="eyebrow">Create Receipt</p>
      <h1>Lock the facts. Shape the story.</h1>
      <p>Keep GitHub evidence intact, add context, and preview the public receipt before it feeds your profile and app page.</p>
    </section>
    ${publishJourney(2, {
      compact: true,
      title: "This is where activity becomes a receipt.",
      copy: "Facts stay source-linked. Your note explains what changed, why it mattered, and what the shipped work unlocked."
    })}
    <section class="studio-grid">
      <article class="evidence-panel"><h2>Raw evidence</h2><div class="pr-list"><div><b>#184</b><span>Discovery filters</span><em>Included</em></div><div><b>#188</b><span>Release notes importer</span><em>Included</em></div><div><b>#191</b><span>Scoring tests</span><em>Included</em></div></div></article>
      <article class="editor-panel"><h2>Annotation</h2><label>Receipt title<input value="SideProject Radar v2.1"></label><label>Builder note<textarea>Moved from prototype to weekly-use product with release notes imported from GitHub.</textarea></label><label class="check"><input type="checkbox" checked> Hide private repo names</label></article>
      <article class="fact-split-panel">
        <div><span>Locked</span><b>PRs, tags, checks, timestamps</b></div>
        <div><span>Editable</span><b>Title, builder note, app context</b></div>
        <div><span>Private</span><b>Repo names, client work, excluded sources</b></div>
      </article>
      <article class="preview-panel"><h2>Public preview</h2>${receiptCard(releases[0], { compact: true })}<div class="action-row small"><a class="primary" href="#/receipt">Publish receipt</a><a class="secondary light" href="#/profile">Preview profile</a></div></article>
    </section>
  `);
}

function builderCardPage() {
  return shell(`
    <section class="page-hero">
      <p class="eyebrow">Builder Card</p>
      <h1>Stop sending resumes.</h1>
      <p class="lede">Send proof.</p>
      <p>Claim a dynamic builder card backed by GitHub releases, merged PRs, and shipped apps.</p>
    </section>
    ${publishJourney(0, {
      compact: true,
      title: "Your card works before the network exists.",
      copy: "Use it as a bio link, profile preview, and proof resume teaser before Connect, Showcase, or Talent matter."
    })}
    <section class="builder-card-layout">
      <article class="builder-card-demo-panel">
        ${builderLinkCard({ id: "setup-builder-card" })}
      </article>
      <aside class="builder-card-settings">
        <div class="panel-heading"><span>Setup</span><h2>Four obvious steps</h2></div>
        <ol class="checklist">
          <li class="done"><b>Claim your card</b><span>@maya.codes proof link reserved</span></li>
          <li class="done"><b>Connect GitHub</b><span>OAuth connected with selected repo access</span></li>
          <li class="done"><b>Choose what counts</b><span>2 public repos, 1 private repo with redaction</span></li>
          <li><b>Publish your proof resume</b><span>Share in bio, resume, email signature, X, LinkedIn, or personal site</span></li>
        </ol>
        <div class="card-setting-grid">
          <label><span>Theme</span><b>Midnight proof</b></label>
          <label><span>Front</span><b>PR distribution</b></label>
          <label><span>Back tabs</span><b>Releases + Apps</b></label>
          <label><span>Privacy</span><b>Private repo names hidden</b></label>
        </div>
        <div class="action-row small"><a class="primary" href="#/profile">Publish proof resume</a><a class="secondary light" href="#/studio">Create receipt</a></div>
      </aside>
    </section>
  `);
}

function trustPage() {
  const rules = [
    ["What PRBar reads", "Release tags, merged PR metadata, selected repo names, labels, timestamps, and test/status context."],
    ["What PRBar counts", "Features shipped, PRs merged, releases made, projects launched, streaks, and verified source links."],
    ["What PRBar protects", "Private repo names, client identities, excluded repos, and any source the builder did not select."],
    ["What PRBar does not count", "Token usage, model spend, prompt volume, screenshots without source proof, or self-reported velocity."],
    ["Anti-gaming", "Ranks show receipts behind the score, age out stale bursts, and flag suspicious source patterns."],
  ];

  return shell(`
    <section class="page-hero">
      <p class="eyebrow">Trust rules</p>
      <h1>Proof needs rules.</h1>
      <p>Make shipping visible without exposing private work or rewarding vanity metrics.</p>
    </section>
    <section class="trust-grid">
      ${rules.map(([title, copy]) => `<article><h2>${title}</h2><p>${copy}</p></article>`).join("")}
    </section>
  `);
}

function placeholderPage(label) {
  return shell(`
    <section class="page-hero">
      <p class="eyebrow">Route not found</p>
      <h1>${label}</h1>
      <p>This mockup route is not part of the current prototype walkthrough.</p>
      <div class="action-row"><a class="primary" href="#/boards">Back to Showcase</a><a class="secondary light" href="#/network">Open Connect</a></div>
    </section>
  `);
}

function initializeBuilderLinkCards() {
  document.querySelectorAll("[data-builder-link-card]").forEach((card) => {
    const frontButton = card.querySelector('[data-card-side="front"]');
    const backButton = card.querySelector('[data-card-side="back"]');
    const tabs = Array.from(card.querySelectorAll("[data-link-card-tab]"));
    const panels = Array.from(card.querySelectorAll("[data-link-card-panel]"));

    const setFlipped = (flipped) => {
      card.classList.toggle("flipped", flipped);
      frontButton?.classList.toggle("active", !flipped);
      backButton?.classList.toggle("active", flipped);
    };

    frontButton?.addEventListener("click", () => setFlipped(false));
    backButton?.addEventListener("click", () => setFlipped(true));

    tabs.forEach((button) => {
      button.addEventListener("click", () => {
        tabs.forEach((item) => {
          const active = item === button;
          item.classList.toggle("active", active);
          item.setAttribute("aria-selected", String(active));
        });
        panels.forEach((panel) => panel.classList.toggle("active", panel.dataset.linkCardPanel === button.dataset.linkCardTab));
      });
    });

    card.addEventListener("pointermove", (event) => {
      if (card.classList.contains("flipped")) return;
      const rect = card.getBoundingClientRect();
      const px = (event.clientX - rect.left) / rect.width;
      const py = (event.clientY - rect.top) / rect.height;
      card.style.setProperty("--tilt-x", `${(px - 0.5) * 9}deg`);
      card.style.setProperty("--tilt-y", `${(0.5 - py) * 7}deg`);
      card.style.setProperty("--glare-x", `${px * 100}%`);
      card.style.setProperty("--glare-y", `${py * 100}%`);
      card.style.setProperty("--glare-opacity", "0.22");
    });

    card.addEventListener("pointerleave", () => {
      card.style.setProperty("--tilt-x", "0deg");
      card.style.setProperty("--tilt-y", "0deg");
      card.style.setProperty("--glare-x", "50%");
      card.style.setProperty("--glare-y", "30%");
      card.style.setProperty("--glare-opacity", "0.14");
    });
  });
}

function render() {
  const path = routePath();
  if (path === "/home") app.innerHTML = homePage();
  if (path === "/network") app.innerHTML = networkPage();
  if (path === "/boards") app.innerHTML = boardsPage();
  if (path === "/talent") app.innerHTML = talentPage();
  if (path === "/dashboard") app.innerHTML = dashboardPage();
  if (path === "/profile") app.innerHTML = profilePage();
  if (path === "/card") app.innerHTML = builderCardPage();
  if (path === "/receipt") app.innerHTML = receiptPage();
  if (path === "/project") app.innerHTML = projectPage();
  if (path === "/repos") app.innerHTML = reposPage();
  if (path === "/studio") app.innerHTML = studioPage();
  if (path === "/trust") app.innerHTML = trustPage();
  if (!routes.some((route) => route.path === path)) app.innerHTML = placeholderPage("Home");

  if (lastRenderedPath !== path) {
    window.scrollTo({ top: 0, behavior: "instant" });
    window.requestAnimationFrame(() => window.scrollTo({ top: 0, behavior: "instant" }));
    window.setTimeout(() => window.scrollTo({ top: 0, behavior: "instant" }), 50);
    lastRenderedPath = path;
  }

  document.querySelectorAll("[data-board]").forEach((button) => {
    button.addEventListener("click", () => {
      app.innerHTML = boardsPage(button.dataset.board);
      window.scrollTo({ top: 0, behavior: "instant" });
    });
  });

  document.querySelectorAll("[data-filter]").forEach((button) => {
    button.addEventListener("click", () => {
      app.innerHTML = talentPage(button.dataset.filter);
      window.scrollTo({ top: 0, behavior: "instant" });
    });
  });

  document.querySelectorAll("[data-section]").forEach((link) => {
    link.addEventListener("click", () => {
      writeActiveSection(link.dataset.section);
    });
  });

  initializeBuilderLinkCards();

  const toggle = document.querySelector("[data-toc-toggle]");
  const collapsed = readTocCollapsed();
  document.body.classList.toggle("toc-collapsed", collapsed);

  if (toggle) {
    toggle.setAttribute("aria-pressed", String(collapsed));
    toggle.setAttribute("aria-label", collapsed ? "Show table of contents" : "Hide table of contents");
    toggle.addEventListener("click", () => {
      const nextCollapsed = !document.body.classList.contains("toc-collapsed");
      document.body.classList.toggle("toc-collapsed", nextCollapsed);
      writeTocCollapsed(nextCollapsed);
      toggle.setAttribute("aria-pressed", String(nextCollapsed));
      toggle.setAttribute("aria-label", nextCollapsed ? "Show table of contents" : "Hide table of contents");
    });
  }
}

window.addEventListener("hashchange", render);

if (!window.location.hash) {
  setRoute("/home");
} else {
  render();
}
