const routes = [
  { path: "/home", label: "Home" },
  { path: "/signup", label: "Sign Up" },
  { path: "/signin", label: "Sign In" },
  { path: "/login", label: "Login" },
  { path: "/logout", label: "Logout" },
  { path: "/onboarding", label: "Onboarding" },
  { path: "/connect-github", label: "Connect GitHub" },
  { path: "/network", label: "Archived Browser" },
  { path: "/boards", label: "App Pages" },
  { path: "/talent", label: "Future Search" },
  { path: "/dashboard", label: "Sources & Privacy" },
  { path: "/profile", label: "Builder Proof" },
  { path: "/user", label: "User Profile" },
  { path: "/edit-profile", label: "Edit Profile" },
  { path: "/account", label: "Account & Permissions" },
  { path: "/card", label: "Builder Card" },
  { path: "/receipt", label: "Receipt" },
  { path: "/project", label: "App Page" },
  { path: "/repos", label: "Sources & Privacy" },
  { path: "/studio", label: "Edit Receipt" },
  { path: "/trust", label: "Trust Rules" },
];

const primaryNavPaths = ["/home", "/profile", "/repos"];

const routeGroups = [
  {
    title: "Home",
    path: "/home",
    routes: [
      { path: "/signup", label: "Sign Up" },
      { path: "/signin", label: "Sign In" },
      { path: "/login", label: "Login" },
      { path: "/onboarding", label: "Onboarding" },
      { path: "/connect-github", label: "Connect GitHub" },
    ],
  },
  {
    title: "Builder Proof",
    path: "/profile",
    routes: [
      { path: "/user", label: "User Profile" },
      { path: "/edit-profile", label: "Edit Profile" },
    ],
  },
  {
    title: "Sources & Privacy",
    path: "/repos",
    routes: [
      { path: "/account", label: "Account & Permissions" },
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
    stats: { prs: 42, releases: 4, repos: 6, apps: 2 },
    proof: "42 merged PRs, 4 releases, and 2 public apps moved from prototype to shipped.",
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
    stats: { prs: 31, releases: 3, repos: 4, apps: 1 },
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
    stats: { prs: 24, releases: 2, repos: 3, apps: 1 },
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
    proof: ["42 PRs", "4 releases", "v2.1.0", "2 apps"],
    repos: ["maya/sideproject-radar", "maya/radar-ios"],
    receipt: releases[0],
    score: "3 receipts",
    pick: "Verified app",
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
    proof: ["31 PRs", "3 releases", "Stripe", "source linked"],
    repos: ["nora/launch-sprint-kit"],
    receipt: releases[1],
    score: "2 receipts",
    pick: "Source linked",
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
    proof: ["24 PRs", "2 releases", "SwiftUI", "redacted proof"],
    repos: ["devon/proof-cards-ios", "devon/proof-card-renderer"],
    receipt: releases[2],
    score: "2 receipts",
    pick: "Recently shipped",
    color: "#2f6fed",
  },
];

const repoSources = [
  { name: "maya/sideproject-radar", visibility: "public", status: "included", lastRelease: "v2.1.0", activity: "18 PRs in 14 days", app: "SideProject Radar", publicImpact: "Shows repo name, release tags, and receipt links." },
  { name: "maya/radar-ios", visibility: "private", status: "included", lastRelease: "v1.4.1", activity: "9 PRs in 14 days", app: "SideProject Radar", publicImpact: "Counts PRs and releases; repo name hidden until approved." },
  { name: "client/stealth-onboarding", visibility: "private", status: "redacted", lastRelease: "hidden", activity: "5 PRs counted", app: "Private client app", publicImpact: "Counts selected facts only; client and repo names hidden." },
  { name: "maya/experiments", visibility: "public", status: "excluded", lastRelease: "none", activity: "prototype only", app: "Prototype Lab", publicImpact: "Does not appear on Builder Proof." },
];

const timeline = [
  { date: "May 26", title: "SideProject Radar v2.1", detail: "8 PRs merged, release notes imported, scoring tests added." },
  { date: "May 21", title: "Discovery filters", detail: "Search filters and saved list UI landed across 3 linked PRs." },
  { date: "May 17", title: "Radar scoring beta", detail: "First public receipt generated from selected repo activity." },
];

const trustRules = [
  ["What PRBar reads", "Release tags, merged PR metadata, selected repo names, labels, timestamps, and test/status context."],
  ["What PRBar counts", "Features shipped, PRs merged, releases made, projects launched, selected sources, and verified source links."],
  ["What PRBar protects", "Private repo names, client identities, excluded repos, and any source the builder did not select."],
  ["How redaction works", "Public receipts can count selected facts while hiding repo names, client labels, and sensitive app context."],
  ["No vanity metrics", "PRBar does not count token usage, model spend, prompt volume, screenshots without source proof, or self-reported velocity."],
];

const boardViews = {
  apps: {
    label: "Apps",
    eyebrow: "App pages",
    description: "Inspect apps with selected repos, release receipts, and shipped feature proof attached.",
    items: showcaseApps,
  },
};

const boardFilters = ["Recent proof", "AI apps", "iOS", "SaaS", "Devtools", "Public beta", "Available builders"];

const boardPicks = [
  { label: "Verified app page", title: "SideProject Radar", copy: "Real app, selected repos, release notes, and inspectable shipped-feature proof." },
  { label: "Source-linked", title: "Launch Sprint Kit", copy: "The product story is easy to inspect because every receipt points back to selected sources." },
  { label: "Recently shipped", title: "iOS Proof Cards", copy: "Strong native proof surface with app context and private-source redaction." },
];

const magicSteps = [
  {
    step: "01",
    title: "Claim builder card",
    copy: "Reserve a compact proof link you can use in bios, resumes, intros, and launch notes.",
    path: "/profile",
  },
  {
    step: "02",
    title: "Connect GitHub",
    copy: "Import release tags, merged PRs, checks, and repo activity from the sources you approve.",
    path: "/repos",
  },
  {
    step: "03",
    title: "Choose sources",
    copy: "Pick the repos and apps that count, redact private work, and leave experiments out of the public story.",
    path: "/repos",
  },
  {
    step: "04",
    title: "Publish Builder Proof",
    copy: "Turn selected repos, apps, releases, and receipts into Builder Proof.",
    path: "/profile",
  },
  {
    step: "05",
    title: "Share anywhere",
    copy: "Copy the card link, Builder Proof link, or receipt URL into bios, resumes, intros, and launch notes.",
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
  if (path === "/dashboard") return "/repos";
  if (["/signup", "/signin", "/login", "/logout", "/onboarding", "/connect-github"].includes(path)) return "/home";
  if (["/card", "/receipt", "/project"].includes(path)) return "/profile";
  if (["/user", "/edit-profile"].includes(path)) return "/profile";
  if (["/studio", "/trust"].includes(path)) return "/repos";
  if (path === "/account") return "/repos";

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

function writePendingScrollTarget(target) {
  try {
    window.sessionStorage?.setItem("prbar-scroll-target", target);
  } catch {
    // Same-page scrolling is a convenience; routing still works without storage.
  }
}

function takePendingScrollTarget() {
  try {
    const target = window.sessionStorage?.getItem("prbar-scroll-target");
    if (target) window.sessionStorage?.removeItem("prbar-scroll-target");
    return target;
  } catch {
    return null;
  }
}

function scrollToTarget(target) {
  window.requestAnimationFrame(() => {
    document.getElementById(target)?.scrollIntoView({ behavior: "smooth", block: "start" });
  });
}

function readTocCollapsed() {
  try {
    const stored = window.localStorage?.getItem("prbar-review-map-collapsed");
    if (stored !== null) return stored === "true";
  } catch {
    // Fall back to the viewport-aware default below.
  }

  return true;
}

function writeTocCollapsed(collapsed) {
  try {
    window.localStorage?.setItem("prbar-review-map-collapsed", String(collapsed));
  } catch {
    // The mockup still works if browser storage is unavailable.
  }
}

function readSessionState() {
  try {
    const stored = window.localStorage?.getItem("prbar-session");
    if (!stored) return { isAuthenticated: false, githubConnected: false };
    const parsed = JSON.parse(stored);
    return {
      isAuthenticated: Boolean(parsed?.isAuthenticated),
      githubConnected: Boolean(parsed?.githubConnected),
    };
  } catch {
    return { isAuthenticated: false, githubConnected: false };
  }
}

function writeSessionState(nextState) {
  try {
    const current = readSessionState();
    window.localStorage?.setItem("prbar-session", JSON.stringify({ ...current, ...nextState }));
  } catch {
    // Auth state is only for the static mockup. Pages remain directly reachable.
  }
}

function resetSessionState() {
  try {
    window.localStorage?.removeItem("prbar-session");
  } catch {
    // Direct routes still work without local storage.
  }
}

const publicPreviewStorageKey = "prbar-public-preview";

function readPublicPreviewMode() {
  try {
    return window.sessionStorage?.getItem(publicPreviewStorageKey) === "true";
  } catch {
    return false;
  }
}

function writePublicPreviewMode(enabled) {
  try {
    if (enabled) {
      window.sessionStorage?.setItem(publicPreviewStorageKey, "true");
    } else {
      window.sessionStorage?.removeItem(publicPreviewStorageKey);
    }
  } catch {
    // Preview mode is a mock-only convenience.
  }
}

const profileStorageKey = "prbar-profile";

function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>"']/g, (character) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    "\"": "&quot;",
    "'": "&#39;",
  }[character]));
}

function initialsFromName(name) {
  const parts = String(name || "")
    .replace(/[^a-z0-9\s]/gi, " ")
    .trim()
    .split(/\s+/)
    .filter(Boolean);

  if (!parts.length) return "PR";
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return `${parts[0][0]}${parts[parts.length - 1][0]}`.toUpperCase();
}

function linkFromHandle(handle) {
  const slug = String(handle || "")
    .replace(/^@/, "")
    .replace(/[^a-z0-9._-]/gi, "")
    .toLowerCase();

  return `prbar.dev/${slug || "maya"}`;
}

function shortProfilePath(profile = readProfileState()) {
  const path = String(profile.link || "")
    .replace(/^https?:\/\//, "")
    .replace(/^prbar\.dev\/?/, "");

  return `/${path || "maya"}`;
}

function defaultProfileState() {
  const builder = builders[0];
  return {
    availability: builder.availability,
    handle: builder.handle,
    link: linkFromHandle(builder.handle),
    name: builder.name,
    note: "Builder Proof built from selected repos, releases, app updates, and public receipts.",
    title: builder.title,
  };
}

function normalizeProfileState(stored) {
  const defaults = defaultProfileState();
  const next = {
    availability: typeof stored?.availability === "string" && stored.availability.trim() ? stored.availability.trim() : defaults.availability,
    handle: typeof stored?.handle === "string" && stored.handle.trim() ? stored.handle.trim() : defaults.handle,
    name: typeof stored?.name === "string" && stored.name.trim() ? stored.name.trim() : defaults.name,
    note: typeof stored?.note === "string" && stored.note.trim() ? stored.note.trim() : defaults.note,
    title: typeof stored?.title === "string" && stored.title.trim() ? stored.title.trim() : defaults.title,
  };

  next.link = typeof stored?.link === "string" && stored.link.trim() ? stored.link.trim() : linkFromHandle(next.handle);
  next.initials = initialsFromName(next.name);
  return next;
}

function readProfileState() {
  try {
    const stored = window.localStorage?.getItem(profileStorageKey);
    return normalizeProfileState(stored ? JSON.parse(stored) : null);
  } catch {
    return normalizeProfileState(null);
  }
}

function writeProfileState(nextState) {
  try {
    window.localStorage?.setItem(profileStorageKey, JSON.stringify(normalizeProfileState(nextState)));
  } catch {
    // Profile edits are mock-only; public pages still render from defaults.
  }
}

const proofWorkflowStorageKey = "prbar-proof-workflow";
const sourceModes = ["included", "redacted", "excluded"];

function defaultProofWorkflowState() {
  return {
    published: false,
    shareFeedback: "",
    sources: Object.fromEntries(repoSources.map((repo) => {
      const mode = repo.status === "excluded" ? "excluded" : repo.status === "redacted" ? "redacted" : "included";
      const attached = ["maya/sideproject-radar", "maya/radar-ios"].includes(repo.name);

      return [repo.name, {
        attached,
        hidden: repo.visibility === "private" || mode === "redacted",
        mode,
      }];
    })),
  };
}

function normalizeProofWorkflowState(stored) {
  const defaults = defaultProofWorkflowState();
  const savedSources = stored?.sources || {};

  return {
    published: Boolean(stored?.published),
    shareFeedback: typeof stored?.shareFeedback === "string" ? stored.shareFeedback : "",
    sources: Object.fromEntries(repoSources.map((repo) => {
      const base = defaults.sources[repo.name];
      const saved = savedSources[repo.name] || {};
      const mode = sourceModes.includes(saved.mode) ? saved.mode : base.mode;

      return [repo.name, {
        attached: typeof saved.attached === "boolean" ? saved.attached : base.attached,
        hidden: typeof saved.hidden === "boolean" ? saved.hidden : base.hidden,
        mode,
      }];
    })),
  };
}

function readProofWorkflowState() {
  try {
    const stored = window.localStorage?.getItem(proofWorkflowStorageKey);
    return normalizeProofWorkflowState(stored ? JSON.parse(stored) : null);
  } catch {
    return defaultProofWorkflowState();
  }
}

function writeProofWorkflowState(nextState) {
  try {
    window.localStorage?.setItem(proofWorkflowStorageKey, JSON.stringify(normalizeProofWorkflowState(nextState)));
  } catch {
    // Source decisions are mock-only; the page still renders from defaults.
  }
}

function proofSourceMetrics(workflow = readProofWorkflowState()) {
  const items = repoSources.map((repo) => ({ repo, state: workflow.sources[repo.name] }));
  const counted = items.filter((item) => item.state.mode !== "excluded");
  const attached = counted.filter((item) => item.state.attached);
  const hidden = counted.filter((item) => item.state.hidden || item.state.mode === "redacted");
  const excluded = items.filter((item) => item.state.mode === "excluded");

  return {
    attached: attached.length,
    counted: counted.length,
    excluded: excluded.length,
    hidden: hidden.length,
    total: items.length,
  };
}

function sourceStatusLabel(mode) {
  return {
    included: "included",
    redacted: "redacted",
    excluded: "excluded",
  }[mode] || "included";
}

function sourceImpact(repo, state) {
  if (state.mode === "excluded") return "Excluded from public proof, receipts, cards, and source counts.";
  if (state.mode === "redacted") return `${repo.activity} counts publicly, while sensitive names and context stay hidden.`;
  if (state.attached) return `${repo.publicImpact} Attached to Builder Proof.`;
  return `${repo.publicImpact} Counts without an app attachment.`;
}

function sourceRow(repo, workflow) {
  const state = workflow.sources[repo.name];
  const countActive = state.mode === "included";
  const redactActive = state.mode === "redacted";
  const excludeActive = state.mode === "excluded";

  return `
    <article class="source-table-row" data-source-row="${repo.name}">
      <div>
        <h3>${repo.name}</h3>
        <p>${repo.activity} / latest release ${repo.lastRelease}</p>
      </div>
      <span>${repo.visibility}</span>
      <b>${sourceStatusLabel(state.mode)}</b>
      <em>${state.attached ? repo.app : "No app attached"}</em>
      <div class="repo-controls" aria-label="${repo.name} source controls">
        <button class="${countActive ? "active" : ""}" type="button" data-source-id="${repo.name}" data-source-action="include">Include</button>
        <button class="${redactActive ? "active" : ""}" type="button" data-source-id="${repo.name}" data-source-action="redact">Redact</button>
        <button class="${excludeActive ? "active" : ""}" type="button" data-source-id="${repo.name}" data-source-action="exclude">Exclude</button>
        <button class="${state.attached ? "active" : ""}" type="button" data-source-id="${repo.name}" data-source-action="attach">${state.attached ? "Attached" : "Attach app"}</button>
      </div>
      <p class="repo-impact">${sourceImpact(repo, state)}</p>
    </article>
  `;
}

function publishStatusCard(workflow) {
  const metrics = proofSourceMetrics(workflow);
  const profile = readProfileState();

  if (workflow.published) {
    return `
      <div class="control-status-card publish-status-card">
        <span>Publish status</span>
        <b>Builder Proof is live</b>
        <p>Share link ready: ${escapeHtml(profile.link)}. ${metrics.counted} selected sources and ${metrics.attached} attached apps now power the public page.</p>
        <div class="action-row small">
          <a class="primary" href="#/profile" data-proof-action="open-public">Open public Builder Proof</a>
          <button class="secondary light" type="button" data-proof-action="draft">Return to draft</button>
        </div>
      </div>
    `;
  }

  return `
    <div class="control-status-card publish-status-card">
      <span>Publish status</span>
      <b>Draft Builder Proof</b>
      <p>${metrics.counted} selected sources and ${metrics.attached} attached apps are ready. Publish when the public proof resume should go live.</p>
      <button class="primary wide" type="button" data-proof-action="publish">Publish Builder Proof</button>
    </div>
  `;
}

function setupChecklist() {
  const session = readSessionState();
  const workflow = readProofWorkflowState();
  const profile = readProfileState();
  const metrics = proofSourceMetrics(workflow);
  const items = [
    {
      done: session.isAuthenticated && Boolean(profile.name),
      href: "#/edit-profile",
      label: "Profile claimed",
      note: `${profile.handle} is reserved and ready for Builder Proof.`,
    },
    {
      done: session.githubConnected,
      href: "#/connect-github",
      label: "GitHub connected",
      note: session.githubConnected ? "Release tags, merged PRs, and checks are available." : "Connect selected repos before proof can be published.",
    },
    {
      done: session.githubConnected && metrics.counted > 0,
      href: "#/repos",
      label: "Sources chosen",
      note: `${metrics.counted} selected sources, ${metrics.attached} attached apps, ${metrics.excluded} excluded.`,
    },
    {
      done: workflow.published,
      href: "#/repos",
      label: "Builder Proof published",
      note: workflow.published ? "The public proof page is live." : "Publish after sources and profile copy look right.",
    },
    {
      done: workflow.shareFeedback.includes("Copied"),
      href: "#/profile",
      label: "Share link copied",
      note: workflow.shareFeedback || "Copy the card or full Builder Proof link when it is ready.",
    },
  ];
  const completed = items.filter((item) => item.done).length;
  const complete = completed === items.length;

  return `
    <section class="setup-checklist-panel" aria-label="Builder Proof setup checklist">
      <div class="setup-checklist-heading">
        <span>${complete ? "Setup complete" : "Finish setup"}</span>
        <b>${completed}/${items.length} complete</b>
      </div>
      <ol class="setup-checklist">
        ${items.map((item) => `
          <li class="${item.done ? "done" : "pending"}">
            <a href="${item.href}">
              <span>${item.done ? "Done" : "Next"}</span>
              <b>${escapeHtml(item.label)}</b>
              <em>${escapeHtml(item.note)}</em>
            </a>
          </li>
        `).join("")}
      </ol>
    </section>
  `;
}

function topbarAccountControls() {
  const session = readSessionState();
  const profile = readProfileState();
  const previewingPublic = routePath() === "/profile" && session.isAuthenticated && readPublicPreviewMode();

  if (previewingPublic) {
    return `
      <div class="topbar-account" data-auth-state="public-preview">
        <span class="topbar-preview-pill">Public preview</span>
        <button class="topbar-link topbar-button" type="button" data-preview-action="exit">Exit preview</button>
      </div>
    `;
  }

  if (session.isAuthenticated) {
    return `
      <div class="topbar-account" data-auth-state="signed-in">
        <a class="topbar-profile" href="#/user"><span class="avatar mini">${escapeHtml(profile.initials)}</span><b>Profile</b></a>
        <a class="topbar-link" href="${session.githubConnected ? "#/repos" : "#/connect-github"}">${session.githubConnected ? "GitHub connected" : "Connect GitHub"}</a>
        <button class="topbar-link topbar-button" type="button" data-auth-action="logout">Log out</button>
      </div>
    `;
  }

  return `
    <div class="topbar-account" data-auth-state="signed-out">
      <a class="topbar-link" href="#/signin">Sign in</a>
      <a class="topbar-action" href="#/signup">Claim builder card</a>
    </div>
  `;
}

function shell(content) {
  const path = routePath();
  const activeSection = readActiveSection(path);
  const navPaths = !readSessionState().isAuthenticated && path === "/profile" ? ["/home", "/profile"] : primaryNavPaths;
  return `
    <div class="mockup-shell">
      ${tableOfContents(path, activeSection)}
      <div class="mockup-main">
        <header class="topbar">
          <button class="toc-toggle" type="button" aria-label="Show review map" aria-pressed="true" data-toc-toggle title="Toggle review map">
            <span class="panel-icon" aria-hidden="true"><i></i><b></b></span>
          </button>
          <a class="brand" href="#/home" aria-label="PRBar home"><span>PR</span><strong>PRBar</strong></a>
          <nav class="nav" aria-label="Primary navigation">
            ${navPaths.map((path) => routes.find((route) => route.path === path)).filter(Boolean).map((route) => `<a class="${activeSection === route.path ? "active" : ""}" data-section="${route.path}" href="#${route.path}">${route.label}</a>`).join("")}
          </nav>
          ${topbarAccountControls()}
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
        <p>Review map</p>
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

function statPills(items) {
  return `<div class="stat-pills">${items.map((item) => `<span>${item}</span>`).join("")}</div>`;
}

function proofLinks(release, options = {}) {
  const prItems = release.builder.prList.slice(0, options.compact ? 2 : 3).map((pr) => `PR ${pr}`);
  const items = [
    "GitHub release",
    `tag ${release.builder.tag}`,
    ...prItems,
    "repo selected",
    "CI passed",
  ];

  return `
    <div class="source-proof-links ${options.compact ? "compact" : ""}" aria-label="Inspectable GitHub proof">
      ${items.map((item) => `<a href="#/profile" data-scroll-target="latest-receipt">${item}</a>`).join("")}
    </div>
  `;
}

function publishJourney(activeIndex = 0, options = {}) {
  return `
    <section class="journey-strip ${options.compact ? "compact" : ""}" aria-label="Builder Proof workflow">
      <div class="journey-heading">
        <p class="eyebrow">First magic moment</p>
        <h2>${options.title || "Turn GitHub-backed shipped work into Builder Proof people can inspect."}</h2>
        <p>${options.copy || "The private setup starts with sources and ends with a public builder card, receipts, app pages, and Builder Proof."}</p>
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
      ${proofLinks(release, { compact: true })}
      <div class="source-row">
        <code>${release.builder.repo}</code>
        <a href="#/profile" data-scroll-target="latest-receipt">Inspect receipt</a>
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

function shareOutputGrid(options = {}) {
  const compact = options.compact ? " compact" : "";
  const profile = options.profile || readProfileState();
  return `
    <div class="share-output-grid${compact}" aria-label="Share outputs">
      <button type="button"><span>Card link</span><b>Copy ${escapeHtml(shortProfilePath(profile))}</b></button>
      <button type="button"><span>Proof link</span><b>Copy Builder Proof</b></button>
      <button type="button"><span>Image</span><b>Download card</b></button>
      <button type="button"><span>Embed</span><b>Copy snippet</b></button>
    </div>
  `;
}

function builderLinkCard(options = {}) {
  const builder = builders[0];
  const profile = options.profile || readProfileState();
  const appCount = Number.isFinite(options.apps) ? options.apps : builder.stats.apps;
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
                <span>${escapeHtml(profile.handle)}</span>
                <h3>${escapeHtml(profile.name)}</h3>
              </div>
              <div class="avatar">${escapeHtml(profile.initials)}</div>
            </div>
            <p>${escapeHtml(profile.title)}. Proof from selected GitHub repos, releases, and app updates.</p>
            <div class="builder-link-chart" aria-label="Selected GitHub proof summary">
              <i style="height:34%"></i><i style="height:58%"></i><i style="height:42%"></i><i style="height:76%"></i><i style="height:64%"></i><i style="height:100%"></i><i style="height:82%"></i>
            </div>
            <div class="builder-link-stats">
              <div><b>${builder.stats.prs}</b><span>merged PRs</span></div>
              <div><b>${builder.stats.repos}</b><span>active repos</span></div>
              <div><b>${appCount}</b><span>shipped apps</span></div>
            </div>
            <small>Front: shipped proof</small>
          </section>
          <section class="builder-link-face builder-link-back">
            <span class="builder-link-glare" aria-hidden="true"></span>
            <div class="builder-link-identity">
              <div>
                <span>Proof links</span>
                <h3>Open the full proof</h3>
              </div>
              <div class="avatar">${escapeHtml(profile.initials)}</div>
            </div>
            <p>The back stays short: one current receipt, one app page, and one path into full Builder Proof.</p>
            <div class="builder-link-list active">
              <a href="#/profile" data-scroll-target="latest-receipt">
                <span><strong>${releases[0].title}</strong><em>${releases[0].facts.slice(0, 2).join(" · ")}</em></span>
                <b>Receipt</b>
              </a>
              <a href="#/profile" data-scroll-target="app-proof">
                <span><strong>${showcaseApps[0].name}</strong><em>${showcaseApps[0].status} · app page</em></span>
                <b>App</b>
              </a>
              <a href="#/profile">
                <span><strong>Maya’s Builder Proof</strong><em>Receipts, apps, timeline</em></span>
                <b>Full</b>
              </a>
            </div>
            <small>Back: card links</small>
          </section>
        </div>
      </div>
      <div class="builder-link-controls" aria-label="Builder card controls">
        <button class="active" type="button" data-card-side="front">Front: Proof</button>
        <button type="button" data-card-side="back">Back: Links</button>
      </div>
    </div>
  `;
}

function proofSummaryCard(builder, options = {}) {
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
        <span><strong>${builder.stats.apps}</strong> apps</span>
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
        <a href="#/receipt" aria-label="Inspect proof for ${app.name}">Proof</a>
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
          ${proofLinks(app.receipt, { compact: true })}
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
              <a href="#/receipt">Receipts behind this app</a>
            </div>
          </div>
        </div>
      </div>
    </article>
  `;
}

function miniProofHistogram() {
  return `
    <div class="mini-proof-histogram" aria-label="Receipt proof summary">
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

function homePage() {
  const profile = readProfileState();
  return shell(`
    <section class="hero">
      <div class="hero-copy">
        <p class="eyebrow">The new resume for AI-native builders</p>
        <h1>Turn shipped work into Builder Proof.</h1>
        <p class="lede">PRBar is a proof resume built from PRs, releases, app updates, and shipped features.</p>
        <p class="hero-proof-line">Claim a builder card, connect GitHub, choose what counts, publish Builder Proof, and share one inspectable link anywhere.</p>
        <div class="action-row">
          <a class="primary" href="#/signup">Claim builder card</a>
          <a class="secondary" href="#/profile">Open Builder Proof</a>
        </div>
      </div>
      <div class="hero-proof">
        ${builderLinkCard({ id: "home-builder-card" })}
      </div>
    </section>
    <section class="home-doorway" aria-label="PRBar product preview">
      <div class="doorway-intro">
        <h2>One link that opens into proof.</h2>
        <p>PRBar stays useful before any network exists: claim the card, connect GitHub, choose the sources that count, and publish a proof surface people can inspect.</p>
      </div>
      <div class="doorway-grid">
        <a class="doorway-panel card-preview" href="#/profile" data-scroll-target="builder-card">
          <span>01 / Builder card</span>
          <strong>Short enough for a bio.</strong>
          <p>A compact share card previews the current proof and points to the full Builder Proof page.</p>
          <div class="mini-card-preview">
            <b>${escapeHtml(profile.initials)}</b>
            <i></i><i></i><i></i>
          </div>
        </a>
        <a class="doorway-panel proof-preview" href="#/profile">
          <span>02 / Builder Proof</span>
          <strong>Deep enough to inspect.</strong>
          <p>Receipts, app proof, releases, PRs, and timeline sit together as a new resume for shipped work.</p>
          <div class="proof-mini-list">
            <em>42 merged PRs</em>
            <em>4 releases</em>
            <em>2 shipped apps</em>
          </div>
        </a>
        <a class="doorway-panel sources-preview" href="#/repos">
          <span>03 / Sources</span>
          <strong>Controlled by the builder.</strong>
          <p>Private source selection and redaction keep proof useful without exposing work that should stay private.</p>
          <div class="source-mini-table">
            <b>Included</b><small>3 sources</small>
            <b>Hidden names</b><small>2 private</small>
          </div>
        </a>
      </div>
    </section>
    <section class="proof-manifesto">
      <p>No feed. No threads. No productivity theater. Just proof.</p>
    </section>
    <section class="home-flow">
      <div>
        <span>Path to value</span>
        <h2>From card to proof in one pass.</h2>
      </div>
      <ol>
        ${magicSteps.map((item) => `<li><b>${item.step}</b><strong>${item.title}</strong><p>${item.copy}</p></li>`).join("")}
      </ol>
    </section>
  `);
}

function networkPage() {
  return shell(`
    <section class="page-hero">
      <p class="eyebrow">Archived concept</p>
      <h1>Proof browsing is not the core product.</h1>
      <p>The current mockup keeps discovery out of the main IA. Start with Builder Proof, then inspect individual receipts or app pages.</p>
    </section>
    <section class="surface-grid">
      <a class="surface-card" href="#/profile"><span>01</span><h2>Builder Proof</h2><p>The canonical full record for a builder.</p></a>
      <a class="surface-card" href="#/receipt"><span>02</span><h2>Receipt</h2><p>One source-linked proof event.</p></a>
      <a class="surface-card" href="#/project"><span>03</span><h2>App Page</h2><p>What the proof shipped.</p></a>
    </section>
  `);
}

function boardsPage(activeView = "apps") {
  const view = boardViews[activeView] || boardViews.apps;
  const featured = view.items[0];
  return shell(`
    <section class="page-hero dark">
      <p class="eyebrow">${view.eyebrow}</p>
      <h1>App pages show what shipped.</h1>
      <p>Browse projects backed by releases, PRs, and app updates.</p>
      ${proofChain(["Builder publishes proof", "App gets attached", "Receipts verify it", "Builder Proof links out"])}
      <div class="board-filterbar" aria-label="Showcase filters">
        ${boardFilters.map((filter, index) => `<button class="${index === 0 ? "active" : ""}" type="button">${filter}</button>`).join("")}
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
          <div><strong>${featured.score}</strong><span>source receipts</span></div>
        </div>
        ${sparkline(featured.builder.trend)}
        <div class="app-links spotlight-links">
          <a href="#/project">Open app page</a>
          <a href="#/receipt">View receipt</a>
          <a href="#/profile">View Builder Proof</a>
        </div>
      </article>
      <div class="board-main">
        <div class="board-list">
          ${view.items.map((item, index) => showcaseAppCard(item, index)).join("")}
        </div>
        <aside class="board-rail">
          <h2>How apps become proof</h2>
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
  return shell(`
    <section class="page-hero">
      <p class="eyebrow">Future concept</p>
      <h1>Builder search comes later.</h1>
      <p>PRBar's immediate value is a builder-owned proof surface. Search and discovery can build on that once people have proof worth finding.</p>
    </section>
    <section class="surface-grid">
      <a class="surface-card" href="#/profile"><span>01</span><h2>Builder Proof</h2><p>Show the work before asking anyone to search it.</p></a>
      <a class="surface-card" href="#/card"><span>02</span><h2>Builder Card</h2><p>Share a compact proof link anywhere.</p></a>
      <a class="surface-card" href="#/repos"><span>03</span><h2>Sources</h2><p>Choose the proof inputs first.</p></a>
    </section>
  `);
}

function setupStepper(activePath) {
  const steps = [
    ["/signup", "Claim card"],
    ["/connect-github", "Connect GitHub"],
    ["/repos", "Choose sources"],
    ["/profile", "Publish Builder Proof"],
  ];

  return `
    <ol class="setup-stepper" aria-label="Builder Proof setup steps">
      ${steps.map(([path, label], index) => `<li class="${path === activePath ? "active" : ""}"><span>${String(index + 1).padStart(2, "0")}</span><a href="#${path}">${label}</a></li>`).join("")}
    </ol>
  `;
}

function authPage(mode = "signup") {
  const isSignup = mode === "signup";
  return shell(`
    <section class="auth-layout">
      <div class="auth-copy">
        <p class="eyebrow">${isSignup ? "Claim builder card" : "Welcome back"}</p>
        <h1>${isSignup ? "Start with the short proof link." : "Sign in to manage Builder Proof."}</h1>
        <p>${isSignup ? "Reserve your builder card, then connect GitHub and choose the sources that power Builder Proof." : "Log in to reach your profile, GitHub connection, account controls, and logout state."}</p>
        ${setupStepper(isSignup ? "/signup" : "/profile")}
      </div>
      <form class="auth-panel">
        <h2>${isSignup ? "Create your PRBar account" : "Sign in"}</h2>
        <label>Email<input type="email" value="${isSignup ? "maya@example.com" : "maya@example.com"}"></label>
        <label>Password<input type="password" value="builderproof"></label>
        ${isSignup ? `<label>Builder handle<input value="@maya.codes"></label>` : ""}
        <a class="primary wide" href="${isSignup ? "#/connect-github" : "#/user"}" data-auth-action="${isSignup ? "signup" : "login"}">${isSignup ? "Continue to GitHub" : "Sign in"}</a>
        ${isSignup ? "" : `<div class="auth-next-links"><a href="#/user">Profile</a><a href="#/connect-github">Connect GitHub</a><a href="#/account">Account</a></div>`}
        <p>${isSignup ? "Already claimed a card?" : "Need a builder card?"} <a href="#/${isSignup ? "signin" : "signup"}">${isSignup ? "Sign in" : "Create account"}</a></p>
      </form>
    </section>
  `);
}

function onboardingPage() {
  return shell(`
    <section class="page-hero">
      <p class="eyebrow">Onboarding</p>
      <h1>Publish Builder Proof in four moves.</h1>
      <p>PRBar keeps setup narrow: claim the card, connect GitHub, choose sources, then publish the proof resume.</p>
      ${setupStepper("/signup")}
    </section>
    <section class="onboarding-panels">
      <a href="#/signup"><span>01</span><h2>Claim card</h2><p>Reserve the short proof link for bios, resumes, and intros.</p></a>
      <a href="#/connect-github"><span>02</span><h2>Connect GitHub</h2><p>Import release tags, merged PR metadata, and checks from approved sources.</p></a>
      <a href="#/repos"><span>03</span><h2>Choose sources</h2><p>Count, attach, redact, or exclude sources before anything goes public.</p></a>
      <a href="#/profile"><span>04</span><h2>Publish proof</h2><p>Share the builder card or full Builder Proof anywhere.</p></a>
    </section>
  `);
}

function connectGithubPage() {
  return shell(`
    <section class="connect-layout">
      <div class="connect-copy">
        <p class="eyebrow">Connect GitHub</p>
        <h1>Bring in the facts, then choose what counts.</h1>
        <p>PRBar reads release tags, merged PR metadata, checks, and selected repo names. You decide which sources appear publicly.</p>
        ${setupStepper("/connect-github")}
      </div>
      <aside class="connect-panel">
        <h2>github.com/maya</h2>
        <p>Selected repo access requested. Private repositories remain hidden until you choose to count or reveal them.</p>
        <div class="permission-list">
          <span>Release tags</span>
          <span>Merged PR metadata</span>
          <span>Status checks</span>
          <span>Selected repo names</span>
        </div>
        <a class="primary wide" href="#/repos" data-auth-action="connect-github">Authorize and choose sources</a>
      </aside>
    </section>
  `);
}

function ownerGatePage(kind = "profile") {
  const profile = readProfileState();
  const gates = {
    account: {
      eyebrow: "Account locked",
      title: "Sign in to manage account permissions.",
      copy: "Account permissions, exports, private source defaults, and deletion controls stay behind the owner session.",
      primary: "Sign in to account",
    },
    edit: {
      eyebrow: "Owner tools locked",
      title: "Sign in to edit this profile.",
      copy: "The public Builder Proof can stay visible while profile copy, handle, availability, and source-backed settings stay owner-only.",
      primary: "Sign in to edit",
    },
    profile: {
      eyebrow: "Owner profile locked",
      title: "Sign in to manage Builder Proof.",
      copy: "Visitors can inspect the public proof. Owners sign in to edit profile copy, connect GitHub, choose sources, and publish updates.",
      primary: "Sign in",
    },
  };
  const gate = gates[kind] || gates.profile;

  return shell(`
    <section class="auth-layout owner-gate-layout">
      <div class="auth-copy">
        <p class="eyebrow">${gate.eyebrow}</p>
        <h1>${gate.title}</h1>
        <p>${gate.copy}</p>
        <div class="action-row"><a class="primary" href="#/signin">${gate.primary}</a><a class="secondary light" href="#/profile">View public Builder Proof</a></div>
      </div>
      <aside class="owner-gate-card">
        <span class="avatar xl">${escapeHtml(profile.initials)}</span>
        <h2>${escapeHtml(profile.name)}</h2>
        <p>${escapeHtml(profile.handle)} · ${escapeHtml(profile.link)}</p>
        <div class="owner-gate-list">
          <b>Public visitors see proof.</b>
          <b>Signed-in owners edit it.</b>
          <b>Potential users can claim their own card.</b>
        </div>
        <a class="primary wide" href="#/signup">Claim your builder card</a>
      </aside>
    </section>
  `);
}

function userProfilePage() {
  const session = readSessionState();
  const workflow = readProofWorkflowState();
  const profile = readProfileState();
  if (!session.isAuthenticated) return ownerGatePage("profile");

  return shell(`
    <section class="account-layout">
      <aside class="account-rail">
        <span class="avatar xl">${escapeHtml(profile.initials)}</span>
        <h2>${escapeHtml(profile.name)}</h2>
        <p>${escapeHtml(profile.handle)} · ${escapeHtml(profile.link)}</p>
        <a class="primary wide" href="#/profile">View public Builder Proof</a>
      </aside>
      <div class="account-main">
        <div class="control-section-heading">
          <span>User profile</span>
          <h1>Manage the identity behind Builder Proof.</h1>
        </div>
        <div class="session-strip">
          <b>${session.isAuthenticated ? "Signed in" : "Static preview"}</b>
          <span>${session.githubConnected ? `${workflow.published ? "Published Builder Proof is live." : "Draft Builder Proof is ready to publish."} ${proofSourceMetrics(workflow).counted} selected sources are available.` : "Connect GitHub to import release tags, merged PRs, and source proof."}</span>
        </div>
        ${setupChecklist()}
        <div class="account-grid">
          <a href="#/edit-profile"><b>Edit profile</b><span>Name, handle, title, availability, and links.</span></a>
          <a href="#/connect-github"><b>${session.githubConnected ? "GitHub connected" : "Connect GitHub"}</b><span>Import PRs, releases, checks, and selected repo names.</span></a>
          <a href="#/account"><b>Account permissions</b><span>GitHub access, private source controls, and export settings.</span></a>
          <a href="#/repos"><b>Sources & Privacy</b><span>Choose what powers public proof.</span></a>
          <a href="#/home" data-auth-action="logout"><b>Log out</b><span>Clear the local mock session and return home.</span></a>
        </div>
      </div>
    </section>
  `);
}

function editProfilePage() {
  if (!readSessionState().isAuthenticated) return ownerGatePage("edit");

  const profile = readProfileState();
  return shell(`
    <section class="account-layout">
      <aside class="account-rail">
        <span class="avatar xl">${escapeHtml(profile.initials)}</span>
        <h2>Public identity</h2>
        <p>This copy appears on the builder card and Builder Proof.</p>
        <a class="secondary light wide" href="#/profile">Preview Builder Proof</a>
      </aside>
      <form class="account-main profile-edit-form" data-profile-form>
        <div class="control-section-heading">
          <span>Edit profile</span>
          <h1>Tune the public resume layer.</h1>
        </div>
        <div class="profile-form-grid">
          <div class="profile-field-stack">
            <label>Name<input name="profile-name" value="${escapeHtml(profile.name)}"></label>
            <label>Handle<input name="profile-handle" value="${escapeHtml(profile.handle)}"></label>
            <label>Proof link<input name="profile-link" value="${escapeHtml(profile.link)}"></label>
            <label>Title<input name="profile-title" value="${escapeHtml(profile.title)}"></label>
            <label>Availability<input name="profile-availability" value="${escapeHtml(profile.availability)}"></label>
            <label>Builder note<textarea name="profile-note">${escapeHtml(profile.note)}</textarea></label>
          </div>
          <aside class="profile-live-preview">
            <span>Public preview</span>
            <div class="mini-public-card">
              <b>${escapeHtml(profile.name)}</b>
              <em>${escapeHtml(profile.handle)}</em>
              <p>${escapeHtml(profile.title)}</p>
              <strong>${escapeHtml(profile.availability)}</strong>
            </div>
            <p>Saving updates the builder card, the account profile, and the published Builder Proof page.</p>
          </aside>
        </div>
        <div class="action-row"><button class="primary" type="button" data-profile-action="save">Save profile</button><a class="secondary light" href="#/profile">Preview Builder Proof</a></div>
      </form>
    </section>
  `);
}

function accountPage() {
  const session = readSessionState();
  const profile = readProfileState();
  if (!session.isAuthenticated) return ownerGatePage("account");

  return shell(`
    <section class="account-layout">
      <aside class="account-rail">
        <h2>Account</h2>
        <p>Permissions and data controls for ${escapeHtml(profile.name)}.</p>
        <a class="primary wide" href="#/repos">Open source controls</a>
      </aside>
      <div class="account-main">
        <div class="control-section-heading">
          <span>Account & permissions</span>
          <h1>Control access, exports, and privacy defaults.</h1>
        </div>
        <div class="permission-cards">
          <article><b>Session</b><span>${session.isAuthenticated ? "Signed in as maya@example.com" : "Signed out preview"}</span><em>${session.isAuthenticated ? "Active" : "Preview"}</em></article>
          <article><b>GitHub</b><span>${session.githubConnected ? "Connected with selected repo access" : "Not connected yet"}</span><em>${session.githubConnected ? "Manage" : "Connect"}</em></article>
          <article><b>Private sources</b><span>Names hidden by default</span><em>Protected</em></article>
          <article><b>Exports</b><span>Card image, embed, and proof link enabled</span><em>Active</em></article>
          <article><b>Delete data</b><span>Remove imported metadata and revoke GitHub</span><em>Available</em></article>
        </div>
        <div class="action-row small"><a class="primary" href="#/connect-github">Connect GitHub</a><button class="secondary light" type="button" data-auth-action="logout">Log out</button></div>
      </div>
    </section>
  `);
}

function logoutPage() {
  return shell(`
    <section class="auth-layout">
      <div class="auth-copy">
        <p class="eyebrow">Signed out</p>
        <h1>You're signed out.</h1>
        <p>The local mock session has been cleared. The public Builder Proof remains shareable, and account controls are one sign-in away.</p>
      </div>
      <aside class="auth-panel">
        <h2>Return to PRBar</h2>
        <a class="primary wide" href="#/signin">Sign in again</a>
        <a class="secondary light wide" href="#/home">Back home</a>
      </aside>
    </section>
  `);
}

function dashboardPage() {
  return reposPage();
}

function unpublishedProfilePage() {
  const profile = readProfileState();
  const session = readSessionState();
  const firstName = profile.name.split(/\s+/).filter(Boolean)[0] || "The builder";
  const actions = session.isAuthenticated
    ? `<a class="primary" href="#/repos">Open owner tools</a><a class="secondary light" href="#/user">Setup checklist</a>`
    : `<a class="primary" href="#/signup">Claim your builder card</a><a class="secondary light" href="#/signin">Sign in to publish</a>`;

  return shell(`
    <section class="public-empty-state">
      <div>
        <p class="eyebrow">Public Builder Proof</p>
        <h1>Builder Proof is not published yet.</h1>
        <p>${escapeHtml(firstName)} has not made this proof resume public. The owner can connect GitHub, choose sources, publish Builder Proof, then share the public link anywhere.</p>
        ${setupStepper("/profile")}
        <div class="action-row">${actions}</div>
      </div>
      <aside class="empty-proof-card">
        <span>Waiting for proof</span>
        <b>Draft only</b>
        <p>No PRs, releases, apps, or receipts are public until the builder publishes.</p>
      </aside>
    </section>
  `);
}

function profileHeroActions(ownerView, publicPreview) {
  if (ownerView) {
    return `
      <div class="action-row small">
        <a class="primary" href="#/profile" data-scroll-target="latest-receipt">Featured receipt</a>
        <button class="secondary light" type="button" data-share-action="proof">Copy Builder Proof link</button>
        <a class="secondary light" href="#/edit-profile">Edit profile</a>
        <a class="secondary light" href="#/repos">Sources & Privacy</a>
      </div>
    `;
  }

  if (publicPreview) {
    return `
      <div class="action-row small">
        <a class="primary" href="#/profile" data-scroll-target="latest-receipt">Featured receipt</a>
        <button class="secondary light" type="button" data-share-action="proof">Copy Builder Proof link</button>
      </div>
    `;
  }

  return `
    <div class="action-row small">
      <a class="primary" href="#/profile" data-scroll-target="latest-receipt">Featured receipt</a>
      <button class="secondary light" type="button" data-share-action="proof">Copy Builder Proof link</button>
      <a class="secondary light" href="#/signup">Create your Builder Proof</a>
    </div>
  `;
}

function ownerProofBar(profile, metrics) {
  return `
    <section class="owner-proof-bar">
      <div>
        <span>Owner view</span>
        <h2>Owner controls</h2>
        <p>You are signed in as the builder. Edit the identity, adjust selected sources, or preview what signed-out visitors see.</p>
      </div>
      <div class="owner-proof-actions">
        <a href="#/edit-profile"><b>Edit profile</b><em>Name, handle, title, and availability.</em></a>
        <a href="#/repos"><b>Sources & Privacy</b><em>${metrics.counted} selected sources power this proof.</em></a>
        <button type="button" data-preview-action="enter"><b>View as public</b><em>Hide owner tools without losing your session.</em></button>
      </div>
    </section>
  `;
}

function publicPreviewBar() {
  return `
    <section class="owner-proof-bar public-preview-bar">
      <div>
        <span>Public preview</span>
        <h2>This is how signed-out visitors see Builder Proof.</h2>
        <p>Editing tools are hidden in this preview. Exit preview to keep editing.</p>
      </div>
      <div class="action-row small"><button class="primary" type="button" data-preview-action="exit">Exit public preview</button></div>
    </section>
  `;
}

function visitorProofCTA(profile) {
  return `
    <section class="visitor-proof-cta">
      <div>
        <span>Potential user view</span>
        <h2>Want proof like this?</h2>
        <p>PRBar turns PRs, releases, app updates, and shipped features into a Builder Proof page you can share anywhere.</p>
      </div>
      <div class="visitor-proof-steps">
        <b>Claim card</b>
        <b>Connect GitHub</b>
        <b>Choose sources</b>
        <b>Publish proof</b>
      </div>
      <div class="action-row small"><a class="primary" href="#/signup">Create your Builder Proof</a><a class="secondary light" href="#/signin">Sign in</a><a class="secondary light" href="#/profile" data-scroll-target="builder-card">Inspect ${escapeHtml(shortProfilePath(profile))}</a></div>
    </section>
  `;
}

function profilePage() {
  const builder = builders[0];
  const profile = readProfileState();
  const release = releases[0];
  const attachedApp = showcaseApps[0];
  const workflow = readProofWorkflowState();
  const metrics = proofSourceMetrics(workflow);
  const session = readSessionState();
  const publicPreview = session.isAuthenticated && readPublicPreviewMode();
  const ownerView = session.isAuthenticated && !publicPreview;

  if (routePath() === "/profile" && !workflow.published) return unpublishedProfilePage();

  return shell(`
    <section class="profile-hero proof-resume-hero">
      <div class="profile-main">
        <span class="avatar xl">${escapeHtml(profile.initials)}</span>
        <div>
          <p class="eyebrow">${workflow.published ? "Published Builder Proof" : "Builder Proof"}</p>
          <h1>${escapeHtml(profile.name)}</h1>
          <p class="profile-handle-line">${escapeHtml(profile.handle)} · ${escapeHtml(profile.link)}</p>
          <p>${escapeHtml(profile.title)}. Shipped 42 merged PRs, 4 releases, and ${metrics.attached} public apps from ${metrics.counted} selected GitHub sources.</p>
          <p class="profile-builder-note">${escapeHtml(profile.note)}</p>
          ${proofChain(["Selected repos", "Released apps", "Merged PRs", "Public receipts"])}
          ${profileHeroActions(ownerView, publicPreview)}
        </div>
      </div>
      <aside class="profile-aside">
        <b>${escapeHtml(profile.availability)}</b>
        ${statPills([...builder.tools, ...builder.domains])}
      </aside>
    </section>
    ${ownerView ? ownerProofBar(profile, metrics) : publicPreview ? publicPreviewBar() : visitorProofCTA(profile)}
    <section class="proof-resume-layout">
      <div class="proof-resume-main">
        <article class="resume-summary-panel">
          <div>
            <span>What this proves</span>
            <h2>42 PRs, 4 releases, ${metrics.attached} apps shipped.</h2>
            <p>${builder.stats.prs} merged PRs, ${builder.stats.releases} releases, and ${metrics.attached} public apps moved from prototype to shipped.</p>
          </div>
          <div class="resume-stat-grid">
            <b><strong>${builder.stats.prs}</strong><span>Merged PRs</span></b>
            <b><strong>${builder.stats.releases}</strong><span>Releases</span></b>
            <b><strong>${metrics.attached}</strong><span>Shipped apps</span></b>
          </div>
        </article>
        <article class="resume-receipt-panel" id="latest-receipt">
          <div class="resume-section-heading">
            <span>Current shipped thing</span>
            <h2>${release.title}</h2>
            <p>${release.summary}</p>
          </div>
          <div class="receipt-proof-layout">
            <div class="receipt-proof-stack">
              ${statPills(release.facts)}
              ${proofLinks(release)}
              <p class="trust-note">Facts are locked from GitHub. Builder annotations add context, but cannot rewrite PRs, tags, checks, or timestamps.</p>
            </div>
            <div class="pr-list">
              ${release.builder.prList.map((pr, index) => `<div><b>${pr}</b><span>${["Discovery filters merged", "Release notes imported", "Scoring tests added"][index]}</span><em>Merged · CI passed</em></div>`).join("")}
            </div>
          </div>
          <blockquote>“This release moved the project from useful prototype to something people can revisit weekly.”</blockquote>
        </article>
        <article class="app-proof-panel" id="app-proof">
          <div class="resume-section-heading">
            <span>App proof</span>
            <h2>Proof attaches to the things Maya shipped.</h2>
          </div>
          <div class="app-proof-strip">
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
        </article>
        <article class="resume-timeline-panel">
          <div class="resume-section-heading">
            <span>Proof timeline</span>
            <h2>Recent shipped work, in order.</h2>
          </div>
          <div class="resume-timeline">
            ${timeline.map((item) => `<article><span>${item.date}</span><div><h3>${item.title}</h3><p>${item.detail}</p></div></article>`).join("")}
          </div>
        </article>
      </div>
      <aside class="proof-share-rail" id="builder-card">
        <div class="rail-sticky">
          <div class="panel-heading"><span>Short version</span><h2>Builder card</h2></div>
          <p>The card is the portable version of this page. It previews the proof, then opens the full Builder Proof when someone wants receipts and source context.</p>
          ${builderLinkCard({ id: "profile-builder-card", compact: true, apps: metrics.attached, profile })}
          <div class="share-output-grid">
            <button type="button" data-share-action="card"><span>Card link</span><b>Copy ${escapeHtml(shortProfilePath(profile))}</b></button>
            <button type="button" data-share-action="proof"><span>Full proof</span><b>Copy Builder Proof</b></button>
            <button type="button" data-share-action="image"><span>Image</span><b>Download card</b></button>
            <button type="button" data-share-action="embed"><span>Embed</span><b>Copy snippet</b></button>
          </div>
          <p class="share-feedback" data-share-feedback>${workflow.shareFeedback || "Share links are ready."}</p>
          <div class="rail-source-note">
            <b>Source controlled</b>
            <span>${metrics.counted} selected sources power the card, receipt, app proof, and timeline.</span>
          </div>
        </div>
      </aside>
    </section>
  `);
}

function receiptPage(options = {}) {
  const release = releases[0];
  const attachedApp = showcaseApps[0];
  const editMode = options.edit === true;
  return shell(`
    <section class="receipt-hero">
      <div>
        <p class="eyebrow">${editMode ? "Edit receipt" : "Release receipt"}</p>
        <h1>${release.title}</h1>
        <p>${release.summary}</p>
        ${statPills(release.facts)}
        ${proofChain(["Release tag v2.1.0", "8 merged PRs", "34 tests added", "Public app proof"])}
        ${proofLinks(release)}
      </div>
      <aside>
        <span>Verified source</span>
        <a href="#/receipt">GitHub release</a>
        <a href="#/receipt">${release.builder.repo}</a>
        <a href="#/receipt">${release.builder.tag}</a>
        <b>${release.date}</b>
      </aside>
    </section>
    <section class="receipt-detail-grid">
      <article class="evidence-panel">
        <h2>Imported GitHub facts</h2>
        <p class="trust-note">Facts are locked from GitHub. Builder annotations can explain what changed, but they cannot rewrite PR, tag, check, or timestamp evidence.</p>
        <div class="pr-list">
          ${release.builder.prList.map((pr, index) => `<div><b>${pr}</b><span>${["Discovery filters merged", "Release notes imported", "Scoring tests added"][index]}</span><em>Merged · CI passed</em></div>`).join("")}
        </div>
      </article>
      <article class="annotation-panel">
        <h2>${editMode ? "Edit annotation" : "Builder annotation"}</h2>
        <p>This release moved the project from useful prototype to something people can revisit weekly. The receipt keeps the facts tied to GitHub while leaving room to explain the product decision.</p>
        ${editMode ? `
          <label>Receipt title<input value="SideProject Radar v2.1"></label>
          <label>Builder note<textarea>Moved from prototype to weekly-use product with release notes imported from GitHub.</textarea></label>
          <label class="check"><input type="checkbox" checked> Hide private repo names</label>
        ` : ""}
        <div class="action-row small"><a class="primary" href="${editMode ? "#/receipt" : "#/studio"}">${editMode ? "Save receipt" : "Edit receipt"}</a><a class="secondary light" href="#/project">View app page</a></div>
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
      <div class="project-links"><a href="#/receipt">Latest receipt</a><a href="#/profile">Builder Proof</a><a href="#/repos">Source repos</a></div>
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

function sourcesEmptyPage() {
  return shell(`
    <section class="public-empty-state">
      <div>
        <p class="eyebrow">Sources & Privacy</p>
        <h1>Connect GitHub to choose sources.</h1>
        <p>Source controls stay private until the builder signs in and authorizes selected repository access.</p>
        ${setupStepper("/connect-github")}
        <div class="action-row"><a class="primary" href="#/connect-github">Connect GitHub</a><a class="secondary light" href="#/signin">Sign in</a></div>
      </div>
      <aside class="empty-proof-card">
        <span>No source access</span>
        <b>0 sources selected</b>
        <p>PR velocity, releases, apps, and receipts appear after GitHub is connected.</p>
      </aside>
    </section>
  `);
}

function reposPage(options = {}) {
  const session = readSessionState();
  const profile = readProfileState();
  const workflow = readProofWorkflowState();
  const metrics = proofSourceMetrics(workflow);
  const sourceRows = repoSources.map((repo) => sourceRow(repo, workflow)).join("");
  const repoApps = repoSources
    .filter((repo) => workflow.sources[repo.name].mode !== "excluded" && workflow.sources[repo.name].attached)
    .map((repo) => ({
      repos: repo.name,
      app: repo.app,
      mode: workflow.sources[repo.name].mode === "redacted" ? "Counts only, names hidden" : "Attached to public proof",
    }));

  if (!session.githubConnected && !options.forceConnected) return sourcesEmptyPage();

  return shell(`
    <section class="page-hero">
      <p class="eyebrow">Sources & Privacy</p>
      <h1>Choose what powers Builder Proof.</h1>
      <p>Only selected GitHub sources become public proof. Everything else stays private, redacted, or excluded.</p>
    </section>
    <section class="control-room">
      <aside class="control-rail">
        <div class="source-summary">
          <h2>${escapeHtml(profile.handle)}</h2>
          <div class="mini-grid">
            <div><strong>${metrics.total}</strong><span>available repos</span></div>
            <div><strong>${metrics.counted}</strong><span>counted</span></div>
            <div><strong>${metrics.hidden}</strong><span>private hidden</span></div>
          </div>
          <p>Private names can stay hidden while merged PR counts and release receipts remain eligible.</p>
        </div>
        <div class="control-status-card">
          <span>Connection</span>
          <b>GitHub connected</b>
          <p>Selected repo access. Release tags, PR metadata, and checks are available for approved sources only.</p>
        </div>
        ${publishStatusCard(workflow)}
        <div class="control-status-card">
          <span>Public preview impact</span>
          <b>${metrics.counted} sources power Builder Proof</b>
          <p>${metrics.attached} attached apps, ${metrics.hidden} private hidden, ${metrics.excluded} excluded. Card, receipt, app proof, and timeline update from the same approved source set.</p>
        </div>
      </aside>
      <div class="control-workbench">
        <section class="source-matrix">
          <div class="control-section-heading">
            <span>Source matrix</span>
            <h2>Choose what counts.</h2>
            <p>Each source has count, app attachment, and redaction controls in one row.</p>
          </div>
          <div class="source-table">
            ${sourceRows}
          </div>
        </section>
        <section class="attachment-editor-grid">
          <article class="app-attachment-panel">
            <div class="control-section-heading">
              <span>App attachments</span>
              <h2>Map sources to what shipped.</h2>
            </div>
            ${repoApps.map((item) => `
              <div class="attachment-row">
                <code>${item.repos}</code>
                <span>${item.app}</span>
                <b>${item.mode}</b>
              </div>
            `).join("") || `<div class="attachment-row empty"><code>No app attachments</code><span>Choose sources</span><b>Draft</b></div>`}
          </article>
          <article class="receipt-editor-panel annotation-panel" id="edit-receipt">
            <div class="control-section-heading">
              <span>Receipt editor</span>
              <h2>Edit latest receipt.</h2>
            </div>
            <p>Receipt editing lives with source controls because this is where public context, redaction, and locked GitHub facts meet.</p>
            <label>Receipt title<input value="SideProject Radar v2.1"></label>
            <label>Builder note<textarea>Moved from prototype to weekly-use product with release notes imported from GitHub.</textarea></label>
            <label class="check"><input type="checkbox" checked> Hide private repo names</label>
            <div class="action-row small"><a class="primary" href="#/profile" data-scroll-target="latest-receipt">Preview on Builder Proof</a><button class="secondary light" type="button">Save receipt</button></div>
          </article>
        </section>
        <section class="trust-rules-panel">
          <div class="control-section-heading">
            <span>Trust rules</span>
            <h2>Trust rules for public proof.</h2>
            <p>Make proof inspectable without turning private work public.</p>
          </div>
          <div class="trust-rule-list">
            ${trustRules.map(([title, copy]) => `
              <article>
                <b>${title}</b>
                <p>${copy}</p>
              </article>
            `).join("")}
          </div>
        </section>
      </div>
    </section>
  `);
}

function studioPage() {
  return receiptPage({ edit: true });
}

function builderCardPage() {
  const profile = readProfileState();
  return shell(`
    <section class="page-hero">
      <p class="eyebrow">Builder Card</p>
      <h1>Builder Proof starts as a builder card.</h1>
      <p class="lede">Short shareable version of Builder Proof.</p>
      <p>Back it with GitHub releases, merged PRs, shipped apps, and selected receipts.</p>
    </section>
    <section class="builder-card-layout">
      <article class="builder-card-demo-panel">
        ${builderLinkCard({ id: "setup-builder-card", profile })}
      </article>
      <aside class="builder-card-settings">
        <div class="panel-heading"><span>Customize card</span><h2>One compact proof link</h2></div>
        <p class="trust-note">Use the builder card anywhere a full page is too much. It previews current proof and opens Builder Proof when someone wants the receipts.</p>
        <div class="card-setting-grid">
          <label><span>Theme</span><b>Midnight proof</b></label>
          <label><span>Front</span><b>Shipped proof</b></label>
          <label><span>Back links</span><b>Receipt + app + proof</b></label>
          <label><span>Privacy</span><b>Private repo names hidden</b></label>
        </div>
        <div class="share-output-grid">
          <button type="button"><span>Card link</span><b>Copy ${escapeHtml(shortProfilePath(profile))}</b></button>
          <button type="button"><span>Image</span><b>Download card</b></button>
          <button type="button"><span>Embed</span><b>Copy snippet</b></button>
          <button type="button"><span>Full proof</span><b>Open Builder Proof</b></button>
        </div>
        <div class="action-row small"><a class="primary" href="#/profile">Open Builder Proof</a><a class="secondary light" href="#/repos">Edit sources</a></div>
      </aside>
    </section>
  `);
}

function trustPage() {
  const rules = [
    ["What PRBar reads", "Release tags, merged PR metadata, selected repo names, labels, timestamps, and test/status context."],
    ["What PRBar counts", "Features shipped, PRs merged, releases made, projects launched, selected sources, and verified source links."],
    ["What PRBar protects", "Private repo names, client identities, excluded repos, and any source the builder did not select."],
    ["How redaction works", "Public receipts can count selected facts while hiding repo names, client labels, and sensitive app context."],
    ["No vanity metrics", "PRBar does not count token usage, model spend, prompt volume, screenshots without source proof, or self-reported velocity."],
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
      <div class="action-row"><a class="primary" href="#/profile">Back to Builder Proof</a><a class="secondary light" href="#/repos">Open Sources</a></div>
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
  if (path === "/home") {
    app.innerHTML = homePage();
  } else if (path === "/signup") {
    app.innerHTML = authPage("signup");
  } else if (["/signin", "/login"].includes(path)) {
    app.innerHTML = authPage("signin");
  } else if (path === "/logout") {
    resetSessionState();
    app.innerHTML = logoutPage();
  } else if (path === "/onboarding") {
    app.innerHTML = onboardingPage();
  } else if (path === "/connect-github") {
    app.innerHTML = connectGithubPage();
  } else if (path === "/network") {
    app.innerHTML = networkPage();
  } else if (path === "/boards") {
    app.innerHTML = boardsPage();
  } else if (path === "/talent") {
    app.innerHTML = talentPage();
  } else if (["/profile", "/card", "/receipt", "/project"].includes(path)) {
    app.innerHTML = profilePage();
  } else if (path === "/user") {
    app.innerHTML = userProfilePage();
  } else if (path === "/edit-profile") {
    app.innerHTML = editProfilePage();
  } else if (path === "/repos") {
    app.innerHTML = reposPage();
  } else if (["/dashboard", "/studio", "/trust"].includes(path)) {
    app.innerHTML = reposPage({ forceConnected: true });
  } else if (path === "/account") {
    app.innerHTML = accountPage();
  } else {
    app.innerHTML = placeholderPage("Home");
  }

  if (lastRenderedPath !== path) {
    window.scrollTo({ top: 0, behavior: "instant" });
    window.requestAnimationFrame(() => window.scrollTo({ top: 0, behavior: "instant" }));
    window.setTimeout(() => window.scrollTo({ top: 0, behavior: "instant" }), 50);
    lastRenderedPath = path;
  }

  const pendingTarget = takePendingScrollTarget();
  if (pendingTarget) window.setTimeout(() => scrollToTarget(pendingTarget), 80);

  document.querySelectorAll("[data-section]").forEach((link) => {
    link.addEventListener("click", () => {
      writeActiveSection(link.dataset.section);
    });
  });

  document.querySelectorAll("[data-scroll-target]").forEach((link) => {
    link.addEventListener("click", (event) => {
      const target = link.dataset.scrollTarget;
      if (!target) return;

      writePendingScrollTarget(target);
      if (link.getAttribute("href") === window.location.hash) {
        event.preventDefault();
        takePendingScrollTarget();
        scrollToTarget(target);
      }
    });
  });

  document.querySelectorAll("[data-auth-action]").forEach((control) => {
    control.addEventListener("click", (event) => {
      const action = control.dataset.authAction;
      const href = control.getAttribute("href");
      const targetPath = href?.startsWith("#") ? href.replace("#", "") : null;

      if (action === "login" || action === "signup") {
        event.preventDefault();
        writeSessionState({ isAuthenticated: true, githubConnected: false });
        if (targetPath) setRoute(targetPath);
        render();
      } else if (action === "connect-github") {
        event.preventDefault();
        writeSessionState({ isAuthenticated: true, githubConnected: true });
        if (targetPath) setRoute(targetPath);
        render();
      } else if (action === "logout") {
        event.preventDefault();
        resetSessionState();
        lastRenderedPath = null;
        setRoute("/home");
        render();
      }
    });
  });

  document.querySelectorAll("[data-profile-action]").forEach((control) => {
    control.addEventListener("click", (event) => {
      const action = control.dataset.profileAction;
      if (action !== "save") return;

      event.preventDefault();
      const form = control.closest("[data-profile-form]");
      const fieldValue = (name) => form?.querySelector(`[name="${name}"]`)?.value || "";
      const handle = fieldValue("profile-handle").trim();
      writeProfileState({
        availability: fieldValue("profile-availability"),
        handle,
        link: fieldValue("profile-link").trim() || linkFromHandle(handle),
        name: fieldValue("profile-name"),
        note: fieldValue("profile-note"),
        title: fieldValue("profile-title"),
      });
      setRoute("/user");
      render();
    });
  });

  document.querySelectorAll("[data-preview-action]").forEach((control) => {
    control.addEventListener("click", (event) => {
      event.preventDefault();
      writePublicPreviewMode(control.dataset.previewAction === "enter");
      render();
    });
  });

  document.querySelectorAll("[data-source-action]").forEach((control) => {
    control.addEventListener("click", () => {
      const sourceId = control.dataset.sourceId;
      const action = control.dataset.sourceAction;
      const modeForAction = { exclude: "excluded", include: "included", redact: "redacted" }[action];
      const workflow = readProofWorkflowState();
      const repo = repoSources.find((item) => item.name === sourceId);
      const source = workflow.sources[sourceId];
      if (!repo || !source) return;

      if (modeForAction) {
        source.mode = modeForAction;
        if (modeForAction === "redacted") source.hidden = true;
        if (modeForAction === "included") source.hidden = repo.visibility === "private" ? source.hidden : false;
        if (modeForAction === "excluded") {
          source.attached = false;
          source.hidden = true;
        }
      } else if (action === "attach") {
        source.attached = !source.attached;
        if (source.attached && source.mode === "excluded") source.mode = "included";
      }

      workflow.published = false;
      workflow.shareFeedback = "";
      writeProofWorkflowState(workflow);
      render();
    });
  });

  document.querySelectorAll("[data-proof-action]").forEach((control) => {
    control.addEventListener("click", (event) => {
      const action = control.dataset.proofAction;
      if (action === "publish" || action === "draft") {
        event.preventDefault();
        const workflow = readProofWorkflowState();
        workflow.published = action === "publish";
        workflow.shareFeedback = "";
        writeProofWorkflowState(workflow);
        render();
      } else if (action === "open-public") {
        event.preventDefault();
        setRoute("/profile");
        render();
      }
    });
  });

  document.querySelectorAll("[data-share-action]").forEach((control) => {
    control.addEventListener("click", () => {
      const labels = {
        card: "Copied builder card link",
        embed: "Copied embed snippet",
        image: "Prepared card image download",
        proof: "Copied Builder Proof link",
      };
      const workflow = readProofWorkflowState();
      workflow.shareFeedback = labels[control.dataset.shareAction] || "Share action copied";
      writeProofWorkflowState(workflow);
      document.querySelectorAll("[data-share-feedback]").forEach((item) => {
        item.textContent = workflow.shareFeedback;
      });
    });
  });

  initializeBuilderLinkCards();

  const toggle = document.querySelector("[data-toc-toggle]");
  const collapsed = readTocCollapsed();
  document.body.classList.toggle("toc-collapsed", collapsed);

  if (toggle) {
    toggle.setAttribute("aria-pressed", String(collapsed));
    toggle.setAttribute("aria-label", collapsed ? "Show review map" : "Hide review map");
    toggle.addEventListener("click", () => {
      const nextCollapsed = !document.body.classList.contains("toc-collapsed");
      document.body.classList.toggle("toc-collapsed", nextCollapsed);
      writeTocCollapsed(nextCollapsed);
      toggle.setAttribute("aria-pressed", String(nextCollapsed));
      toggle.setAttribute("aria-label", nextCollapsed ? "Show review map" : "Hide review map");
    });
  }
}

window.addEventListener("hashchange", render);

if (!window.location.hash) {
  setRoute("/home");
} else {
  render();
}
