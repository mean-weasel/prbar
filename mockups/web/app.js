const routes = [
  { path: "/home", label: "Home" },
  { path: "/network", label: "Connect" },
  { path: "/boards", label: "Boards" },
  { path: "/talent", label: "Talent" },
  { path: "/dashboard", label: "Dashboard" },
  { path: "/profile", label: "Profile" },
  { path: "/receipt", label: "Receipt" },
  { path: "/project", label: "Project" },
  { path: "/repos", label: "Repos" },
  { path: "/studio", label: "Studio" },
  { path: "/trust", label: "Trust" },
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

const networkPosts = releases.map((release, index) => ({
  release,
  action: ["shipped a release", "published a launch receipt", "tagged a proof milestone"][index],
  note: [
    "Seven-day sprint: discovery filters, imported release notes, and scoring tests moved from PR stack to public release.",
    "A founder-ready launch kit landed with billing metrics, onboarding checklists, and a cleaner handoff path.",
    "The iOS receipt flow now supports private repo redaction and native share previews from selected sources.",
  ][index],
  ask: ["Ask about workflow", "Ask about launch sprint", "Ask about iOS proof"][index],
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
  rising: {
    label: "Rising builders",
    eyebrow: "Community-ranked momentum",
    description: "Community votes and PRBar picks spotlight the builders gaining real proof velocity.",
    items: [
      { builder: builders[0], why: "4 releases this week", detail: "Latest receipt ties 8 PRs to a tagged release.", score: "128 votes", pick: "PRBar pick" },
      { builder: builders[1], why: "Launch sprint closed", detail: "Moved billing analytics from PR stack to public release.", score: "97 votes", pick: "Community" },
      { builder: builders[2], why: "11-day active streak", detail: "iOS proof flow shipped across app and shared package.", score: "84 votes", pick: "Rising" },
    ],
  },
  projects: {
    label: "Active projects",
    eyebrow: "Curated project radar",
    description: "Browse projects nominated by the community and featured by PRBar for visible shipping cadence.",
    items: [
      { builder: builders[0], why: "SideProject Radar", detail: "Release cadence: 4 tags in 30 days. Latest: v2.1.0.", score: "Featured", pick: "PRBar pick" },
      { builder: builders[1], why: "Launch Sprint Kit", detail: "Founder-ready kit with billing, onboarding, and handoff receipts.", score: "92 votes", pick: "Community" },
      { builder: builders[2], why: "iOS Proof Cards", detail: "Mobile receipt studio with redaction and native share previews.", score: "71 votes", pick: "Nominated" },
    ],
  },
  releases: {
    label: "New receipts",
    eyebrow: "Fresh featured receipts",
    description: "Vote on proof-backed releases and browse the receipts PRBar thinks deserve a closer look.",
    items: releases.map((release) => ({
      builder: release.builder,
      why: release.title,
      detail: release.summary,
      score: release.facts[0],
      pick: "Fresh",
    })),
  },
};

const app = document.querySelector("#app");

function routePath() {
  const path = window.location.hash.replace("#", "") || "/home";
  return routes.some((route) => route.path === path) ? path : "/home";
}

function setRoute(path) {
  window.location.hash = path;
}

function shell(content) {
  const path = routePath();
  return `
    <header class="topbar">
      <a class="brand" href="#/home" aria-label="PRBar home"><span>PR</span><strong>PRBar</strong></a>
      <nav class="nav" aria-label="Primary navigation">
        ${routes.slice(0, 4).map((route) => `<a class="${path === route.path ? "active" : ""}" href="#${route.path}">${route.label}</a>`).join("")}
      </nav>
      <a class="topbar-action" href="#/dashboard">Claim profile</a>
    </header>
    <main>${content}</main>
  `;
}

function statPills(items) {
  return `<div class="stat-pills">${items.map((item) => `<span>${item}</span>`).join("")}</div>`;
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
        <a href="#/profile">Follow</a>
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
        <p class="eyebrow">GitHub proof for AI-native builders</p>
        <h1>You ship (real) fast with AI.</h1>
        <p class="lede">Show the world your receipts.</p>
        <div class="action-row">
          <a class="primary" href="#/network">Open Connect</a>
          <a class="secondary" href="#/boards">See what is shipping</a>
        </div>
      </div>
      <div class="hero-proof">
        <div class="share-preview" aria-label="PRBar weekly proof of work share card">
          <div class="share-kicker">PRBar · Weekly proof of work</div>
          <div class="share-head">
            <div>
              <strong>42</strong>
              <span>merged PRs</span>
            </div>
            <p><b>This week</b><span>6 active repos</span></p>
          </div>
          <div class="share-histogram">
            <div class="share-histogram-title">
              <span>PR histogram</span>
              <b>by repo</b>
            </div>
            <div class="share-chart" aria-label="Merged pull requests over the week">
              <i>
                <em style="height: 34%; background:#19b394"></em>
              </i>
              <i>
                <em style="height: 36%; background:#19b394"></em>
                <em style="height: 22%; background:#f4c430"></em>
              </i>
              <i>
                <em style="height: 24%; background:#19b394"></em>
                <em style="height: 18%; background:#2f6fed"></em>
              </i>
              <i>
                <em style="height: 42%; background:#19b394"></em>
                <em style="height: 22%; background:#f4c430"></em>
                <em style="height: 12%; background:#2f6fed"></em>
              </i>
              <i>
                <em style="height: 38%; background:#19b394"></em>
                <em style="height: 26%; background:#f4c430"></em>
              </i>
              <i>
                <em style="height: 48%; background:#19b394"></em>
                <em style="height: 30%; background:#f4c430"></em>
                <em style="height: 22%; background:#2f6fed"></em>
              </i>
              <i>
                <em style="height: 44%; background:#19b394"></em>
                <em style="height: 24%; background:#f4c430"></em>
                <em style="height: 14%; background:#2f6fed"></em>
              </i>
            </div>
          </div>
          <div class="share-chart-labels">
            <span>Mon</span>
            <span>Peak 11</span>
            <span>Sun</span>
          </div>
          <div class="share-repos">
            <span><i style="background:#19b394"></i>sideproject-radar<b>18</b></span>
            <span><i style="background:#f4c430"></i>radar-ios<b>14</b></span>
            <span><i style="background:#2f6fed"></i>launch-kit<b>10</b></span>
          </div>
          <div class="share-foot">
            <span>@maya.codes</span>
            <span>PRBAR.APP</span>
          </div>
        </div>
      </div>
    </section>
    <section class="surface-grid">
      <a class="surface-card" href="#/network"><span>01</span><h2>Connect</h2><p>Follow high-velocity AI builders.</p></a>
      <a class="surface-card" href="#/boards"><span>02</span><h2>Momentum Boards</h2><p>Community-ranked momentum, curated by PRBar.</p></a>
      <a class="surface-card" href="#/talent"><span>03</span><h2>Talent Board</h2><p>Scout builders with recent proof, relevant stacks, and clear availability.</p></a>
    </section>
  `);
}

function networkPage() {
  return shell(`
    <section class="page-hero">
      <p class="eyebrow">Connect</p>
      <h1>Follow high-velocity AI builders.</h1>
      <p>See what they shipped, ask how they did it, and keep up with people building at AI speed.</p>
      <div class="network-tabs" aria-label="Connect filters">
        <button class="active" type="button">Receipts</button>
        <button type="button">Builders</button>
        <button type="button">Projects</button>
        <button type="button">Questions</button>
      </div>
    </section>
    <section class="network-layout">
      <div class="feed">
        ${networkPosts.map((post) => networkPost(post)).join("")}
      </div>
      <aside class="side-panel">
        <div class="network-brief">
          <span>Connect signal</span>
          <h2>Receipts start conversations.</h2>
          <p>Follow receipts, ask about workflows, and go deeper into the person and project behind each shipped thing.</p>
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

function boardsPage(activeView = "rising") {
  const view = boardViews[activeView] || boardViews.rising;
  return shell(`
    <section class="page-hero dark">
      <p class="eyebrow">${view.eyebrow}</p>
      <h1>See what deserves attention.</h1>
      <p>${view.description}</p>
      <div class="board-tabs" role="tablist" aria-label="Momentum board views">
        ${Object.entries(boardViews).map(([key, item]) => `<button class="${key === activeView ? "active" : ""}" data-board="${key}" type="button">${item.label}</button>`).join("")}
      </div>
    </section>
    <section class="board-discovery">
      <article class="board-spotlight">
        <span>#1 rising signal</span>
        <h2>${view.items[0].why}</h2>
        <p>${view.items[0].detail}</p>
        <div class="spotlight-grid">
          <div><strong>${view.items[0].builder.stats.prs}</strong><span>merged PRs</span></div>
          <div><strong>${view.items[0].builder.stats.releases}</strong><span>releases</span></div>
          <div><strong>${view.items[0].builder.stats.streak}</strong><span>day streak</span></div>
        </div>
        ${sparkline(view.items[0].builder.trend)}
      </article>
      <div class="board-list">
        ${view.items.map((item, index) => `
          <article class="momentum-card">
            <div class="rank">#${index + 1}</div>
            <div>
              <div class="identity-row compact">
                <span class="avatar">${item.builder.initials}</span>
                <div>
                  <h3>${item.builder.handle}</h3>
                  <p>${item.builder.domains.join(" / ")}</p>
                </div>
                <b>${item.pick}</b>
              </div>
              <h2>${item.why}</h2>
              <p>${item.detail}</p>
              <div class="source-row">
                <code>${item.builder.repo} ${item.builder.tag}</code>
                <div class="board-actions">
                  <span>${item.score}</span>
                  <a href="#/receipt">Receipts behind rank</a>
                  <button type="button">Vote</button>
                </div>
              </div>
            </div>
          </article>
        `).join("")}
      </div>
    </section>
  `);
}

function talentPage(filter = "all") {
  const filtered = filter === "all" ? builders : builders.filter((builder) => builder.domains.map((item) => item.toLowerCase()).includes(filter));
  return shell(`
    <section class="page-hero">
      <p class="eyebrow">Talent Board</p>
      <h1>Find builders with receipts.</h1>
      <p>Search by recent releases, stack, domain, availability, and proof of shipped work.</p>
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
      <h1>Make proof from your week.</h1>
      <p>Review imported GitHub activity, approve receipts, and choose what becomes public.</p>
    </section>
    <section class="workflow-layout">
      <article class="command-panel">
        <div class="panel-heading"><span>Next action</span><h2>3 receipts ready for review</h2></div>
        <ol class="checklist">
          <li class="done"><b>GitHub connected</b><span>@maya.codes synced 11 minutes ago</span></li>
          <li class="done"><b>Repos selected</b><span>2 public, 2 private with redaction enabled</span></li>
          <li><b>Review SideProject Radar v2.1</b><span>Suggested receipt uses 8 merged PRs and release tag v2.1.0</span></li>
          <li><b>Publish share card</b><span>Preview profile, board eligibility, and receipt link</span></li>
        </ol>
        <div class="action-row small"><a class="primary" href="#/studio">Open studio</a><a class="secondary light" href="#/repos">Manage sources</a></div>
      </article>
      <div class="dashboard-stack">
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
          <p class="eyebrow">Proof profile</p>
          <h1>Receipts beat resumes.</h1>
          <p>${builder.handle} ships AI-native mobile and micro-SaaS work backed by selected GitHub repos.</p>
          <div class="action-row small"><a class="primary" href="#/receipt">Featured receipt</a><a class="secondary light" href="#/talent">Find similar builders</a></div>
        </div>
      </div>
      <aside class="profile-aside">
        <b>${builder.availability}</b>
        ${statPills([...builder.tools, ...builder.domains])}
      </aside>
    </section>
    <section class="profile-proof-grid">
      ${builderCard(builder, { featured: true })}
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
  return shell(`
    <section class="receipt-hero">
      <div>
        <p class="eyebrow">Release receipt</p>
        <h1>${release.title}</h1>
        <p>${release.summary}</p>
        ${statPills(release.facts)}
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
    </section>
  `);
}

function projectPage() {
  return shell(`
    <section class="project-hero">
      <p class="eyebrow">Project history</p>
      <h1>Watch the project ship.</h1>
      <p>Track cadence, latest releases, selected repos, and the receipts behind momentum.</p>
      <div class="project-links"><a href="#/receipt">Latest receipt</a><a href="#/profile">Builder profile</a><a href="#/repos">Source repos</a></div>
    </section>
    <section class="project-grid">
      <article class="project-visual"><span>Live proof card</span><strong>4 releases / 30 days</strong>${sparkline([34, 48, 52, 71, 79, 96])}</article>
      <div class="timeline-panel">
        <h2>What changed over time</h2>
        ${timeline.map((item) => `<article><span>${item.date}</span><h3>${item.title}</h3><p>${item.detail}</p></article>`).join("")}
      </div>
    </section>
  `);
}

function reposPage() {
  return shell(`
    <section class="page-hero">
      <p class="eyebrow">Repo sources</p>
      <h1>Choose which repos count.</h1>
      <p>Control profiles, boards, receipts, and private redaction from one source list.</p>
    </section>
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
      <p class="eyebrow">Receipt Studio</p>
      <h1>Shape the receipt.</h1>
      <p>Keep GitHub facts intact, add context, and preview the public card.</p>
    </section>
    <section class="studio-grid">
      <article class="evidence-panel"><h2>Raw evidence</h2><div class="pr-list"><div><b>#184</b><span>Discovery filters</span><em>Included</em></div><div><b>#188</b><span>Release notes importer</span><em>Included</em></div><div><b>#191</b><span>Scoring tests</span><em>Included</em></div></div></article>
      <article class="editor-panel"><h2>Annotation</h2><label>Receipt title<input value="SideProject Radar v2.1"></label><label>Builder note<textarea>Moved from prototype to weekly-use product with release notes imported from GitHub.</textarea></label><label class="check"><input type="checkbox" checked> Hide private repo names</label></article>
      <article class="preview-panel"><h2>Public preview</h2>${receiptCard(releases[0], { compact: true })}<div class="action-row small"><a class="primary" href="#/receipt">Publish receipt</a></div></article>
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
      <div class="action-row"><a class="primary" href="#/boards">Back to Boards</a><a class="secondary light" href="#/network">Open Connect</a></div>
    </section>
  `);
}

function render() {
  const path = routePath();
  if (path === "/home") app.innerHTML = homePage();
  if (path === "/network") app.innerHTML = networkPage();
  if (path === "/boards") app.innerHTML = boardsPage();
  if (path === "/talent") app.innerHTML = talentPage();
  if (path === "/dashboard") app.innerHTML = dashboardPage();
  if (path === "/profile") app.innerHTML = profilePage();
  if (path === "/receipt") app.innerHTML = receiptPage();
  if (path === "/project") app.innerHTML = projectPage();
  if (path === "/repos") app.innerHTML = reposPage();
  if (path === "/studio") app.innerHTML = studioPage();
  if (path === "/trust") app.innerHTML = trustPage();
  if (!routes.some((route) => route.path === path)) app.innerHTML = placeholderPage("Home");

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
}

window.addEventListener("hashchange", render);

if (!window.location.hash) {
  setRoute("/home");
} else {
  render();
}
