"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { appVersionDisplayValue } from "./version";

type SessionState = {
  isAuthenticated: boolean;
  githubConnected: boolean;
};

type ProfileState = {
  availability: string;
  handle: string;
  initials: string;
  link: string;
  name: string;
  note: string;
  title: string;
};

type SourceMode = "included" | "redacted" | "excluded";

type SourceState = {
  attached: boolean;
  hidden: boolean;
  mode: SourceMode;
};

type WorkflowState = {
  draftDirty: boolean;
  published: boolean;
  publicSources: Record<string, SourceState> | null;
  shareFeedback: string;
  shareOutput: string;
  sourcesReviewed: boolean;
  sources: Record<string, SourceState>;
};

type ProductStage = "signed-out" | "new-user" | "connected-draft" | "published-owner" | "public-prospect";

type ProductState = {
  description: string;
  label: string;
  nextPath: string;
  nextText: string;
  stage: ProductStage;
};

type ShareAction = "card" | "proof" | "image" | "embed";

type Source = {
  activity: string;
  app: string;
  lastRelease: string;
  name: string;
  publicImpact: string;
  status: SourceMode;
  visibility: "public" | "private";
};

const sessionKey = "prbar-session";
const profileKey = "prbar-profile";
const workflowKey = "prbar-proof-workflow";

const signedOutRoutes = [
  { label: "Home", path: "/home" },
  { label: "Card", path: "/profile" },
  { label: "Sources", path: "/repos" },
  { label: "Account", path: "/account" },
];

const signedInRoutes = [
  { label: "Home", path: "/home" },
  { label: "Card", path: "/profile" },
  { label: "Sources", path: "/repos" },
  { label: "Account", path: "/account" },
];

const proofRoutes = ["/profile", "/card", "/receipt", "/project"] as const;
type ProofRoute = (typeof proofRoutes)[number];

function isProofRoute(path: string): path is ProofRoute {
  return proofRoutes.includes(path as ProofRoute);
}

function proofAliasTarget(route: ProofRoute) {
  return {
    "/profile": null,
    "/card": "builder-card",
    "/receipt": "latest-receipt",
    "/project": "app-proof",
  }[route];
}

const validRoutes = new Set([
  ...signedOutRoutes.map((route) => route.path),
  ...signedInRoutes.map((route) => route.path),
  "/signup",
  "/signin",
  "/login",
  "/logout",
  "/onboarding",
  "/connect-github",
  "/user",
  ...proofRoutes,
  "/edit-profile",
]);

const builder = {
  availability: "Open to launch sprints",
  domains: ["iOS", "Micro-SaaS", "AI search"],
  handle: "@maya.codes",
  initials: "MC",
  location: "Phoenix, AZ",
  name: "Maya Chen",
  stats: { apps: 2, prs: 42, releases: 4, repos: 6 },
  title: "AI-native mobile and micro-SaaS builder",
  tools: ["Claude Code", "Cursor", "Xcode", "Vercel"],
};

const release = {
  date: "May 26, 2026",
  facts: ["8 PRs merged", "2 repos selected", "v2.1.0 tagged", "34 tests added"],
  prList: ["#184", "#188", "#191"],
  repo: "maya/sideproject-radar",
  summary: "Discovery filters, release-note import, and scoring tests shipped from 8 merged PRs.",
  tag: "v2.1.0",
  title: "SideProject Radar v2.1",
};

const apps = [
  {
    name: "SideProject Radar",
    proof: ["42 PRs", "4 releases", "v2.1.0"],
    status: "Public beta",
    tagline: "A weekly radar for indie products before they trend.",
  },
  {
    name: "Radar iOS",
    proof: ["9 PRs", "1 release", "SwiftUI"],
    status: "TestFlight build",
    tagline: "Native product radar proof attached to selected source work.",
  },
];

const sources: Source[] = [
  {
    activity: "18 PRs in 14 days",
    app: "SideProject Radar",
    lastRelease: "v2.1.0",
    name: "maya/sideproject-radar",
    publicImpact: "Shows repo name, release tags, and receipt links.",
    status: "included",
    visibility: "public",
  },
  {
    activity: "9 PRs in 14 days",
    app: "SideProject Radar",
    lastRelease: "v1.4.1",
    name: "maya/radar-ios",
    publicImpact: "Counts PRs and releases; repo name hidden until approved.",
    status: "included",
    visibility: "private",
  },
  {
    activity: "5 PRs counted",
    app: "Private client app",
    lastRelease: "hidden",
    name: "client/stealth-onboarding",
    publicImpact: "Counts selected facts only; client and repo names hidden.",
    status: "redacted",
    visibility: "private",
  },
  {
    activity: "prototype only",
    app: "Prototype Lab",
    lastRelease: "none",
    name: "maya/experiments",
    publicImpact: "Does not appear on the PRBar card.",
    status: "excluded",
    visibility: "public",
  },
];

const timeline = [
  ["May 26", "SideProject Radar v2.1", "8 PRs merged, release notes imported, scoring tests added."],
  ["May 21", "Discovery filters", "Search filters and saved list UI landed across 3 linked PRs."],
  ["May 17", "Radar scoring beta", "First public receipt generated from selected repo activity."],
];

function initialsFromName(name: string) {
  const parts = name.replace(/[^a-z0-9\s]/gi, " ").trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return "PR";
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return `${parts[0][0]}${parts[parts.length - 1][0]}`.toUpperCase();
}

function linkFromHandle(handle: string) {
  const slug = handle.replace(/^@/, "").replace(/[^a-z0-9._-]/gi, "").toLowerCase();
  return `prbar.dev/${slug || "maya"}`;
}

function defaultProfile(): ProfileState {
  return {
    availability: builder.availability,
    handle: builder.handle,
    initials: builder.initials,
    link: linkFromHandle(builder.handle),
    name: builder.name,
    note: "PRBar card built from selected repos, releases, app updates, and public receipts.",
    title: builder.title,
  };
}

function normalizeProfile(value: Partial<ProfileState> | null): ProfileState {
  const defaults = defaultProfile();
  const next = {
    availability: value?.availability?.trim() || defaults.availability,
    handle: value?.handle?.trim() || defaults.handle,
    link: value?.link?.trim() || "",
    name: value?.name?.trim() || defaults.name,
    note: value?.note?.trim() || defaults.note,
    title: value?.title?.trim() || defaults.title,
  };

  return {
    ...next,
    initials: initialsFromName(next.name),
    link: next.link || linkFromHandle(next.handle),
  };
}

function defaultWorkflow(): WorkflowState {
  return {
    draftDirty: false,
    published: false,
    publicSources: null,
    shareFeedback: "",
    shareOutput: "",
    sourcesReviewed: false,
    sources: Object.fromEntries(
      sources.map((source) => [
        source.name,
        {
          attached: ["maya/sideproject-radar", "maya/radar-ios"].includes(source.name),
          hidden: source.visibility === "private" || source.status === "redacted",
          mode: source.status,
        },
      ]),
    ),
  };
}

function normalizeSourceRecord(value: Partial<Record<string, Partial<SourceState>>> | null | undefined, fallbackRecord: Record<string, SourceState>) {
  return Object.fromEntries(
    sources.map((source) => {
      const saved = value?.[source.name];
      const fallback = fallbackRecord[source.name];
      const mode = saved?.mode === "included" || saved?.mode === "redacted" || saved?.mode === "excluded" ? saved.mode : fallback.mode;
      return [
        source.name,
        {
          attached: typeof saved?.attached === "boolean" ? saved.attached : fallback.attached,
          hidden: typeof saved?.hidden === "boolean" ? saved.hidden : fallback.hidden,
          mode,
        },
      ];
    }),
  );
}

function normalizeWorkflow(value: Partial<WorkflowState> | null): WorkflowState {
  const defaults = defaultWorkflow();
  const normalizedSources = normalizeSourceRecord(value?.sources, defaults.sources);
  const published = Boolean(value?.published);
  const normalizedPublicSources = value?.publicSources
    ? normalizeSourceRecord(value.publicSources, normalizedSources)
    : published
      ? normalizeSourceRecord(normalizedSources, normalizedSources)
      : null;

  return {
    draftDirty: Boolean(value?.draftDirty),
    published,
    publicSources: normalizedPublicSources,
    shareFeedback: typeof value?.shareFeedback === "string" ? value.shareFeedback : "",
    shareOutput: typeof value?.shareOutput === "string" ? value.shareOutput : "",
    sourcesReviewed: Boolean(value?.sourcesReviewed),
    sources: normalizedSources,
  };
}

function readStored<T>(key: string, fallback: T): T {
  if (typeof window === "undefined") return fallback;
  try {
    const stored = window.localStorage.getItem(key);
    return stored ? (JSON.parse(stored) as T) : fallback;
  } catch {
    return fallback;
  }
}

function currentRoute() {
  if (typeof window === "undefined") return "/home";
  const hash = window.location.hash;
  if (hash.startsWith("#/")) {
    const hashPath = hash.slice(1);
    return validRoutes.has(hashPath) ? hashPath : "/home";
  }

  const path = window.location.pathname || "/home";
  if (validRoutes.has(path)) return path;
  return path === "/" ? "/home" : "/profile";
}

function sectionFor(path: string, session?: SessionState) {
  if (path === "/user" || path === "/edit-profile") return "/profile";
  if (["/card", "/receipt", "/project"].includes(path)) return "/profile";
  if (path === "/connect-github") return session?.isAuthenticated ? "/repos" : "/home";
  if (signedInRoutes.some((route) => route.path === path)) return path;
  if (signedOutRoutes.some((route) => route.path === path)) return path;
  return "/home";
}

function sourceMetricsFromRecord(sourceRecord: Record<string, SourceState>) {
  const rows = sources.map((source) => ({ source, state: sourceRecord[source.name] }));
  const counted = rows.filter((row) => row.state.mode !== "excluded");
  const attached = counted.filter((row) => row.state.attached);
  const hidden = counted.filter((row) => row.state.hidden || row.state.mode === "redacted");
  const excluded = rows.filter((row) => row.state.mode === "excluded");

  return {
    attached: attached.length,
    counted: counted.length,
    excluded: excluded.length,
    hidden: hidden.length,
    total: rows.length,
  };
}

function sourceMetrics(workflow: WorkflowState, scope: "draft" | "public" = "draft") {
  return sourceMetricsFromRecord(scope === "public" && workflow.publicSources ? workflow.publicSources : workflow.sources);
}

function setupStepStates(session: SessionState, workflow: WorkflowState) {
  return [
    { done: session.githubConnected, label: "Connect GitHub", path: "/connect-github" },
    { done: session.githubConnected && workflow.sourcesReviewed, label: "Customize", path: "/repos" },
    { done: workflow.published, label: "Publish & share", path: "/profile" },
  ];
}

function productStateFor(session: SessionState, workflow: WorkflowState, publicPreview = false): ProductState {
  if (!session.isAuthenticated) {
    return workflow.published
      ? {
          description: "Signed-out prospect inspecting a live PRBar card.",
          label: "Public prospect view",
          nextPath: "/signup",
          nextText: "Create your PRBar card",
          stage: "public-prospect",
        }
      : {
          description: "Signed-out visitor can inspect the idea and claim a PRBar card.",
          label: "Signed-out visitor",
          nextPath: "/signup",
          nextText: "Claim your card",
          stage: "signed-out",
        };
  }

  if (publicPreview && workflow.published) {
    return {
      description: "Owner is previewing the signed-out public artifact.",
      label: "Public prospect view",
      nextPath: "/profile",
      nextText: "Exit preview",
      stage: "public-prospect",
    };
  }

  if (!session.githubConnected) {
    return {
      description: "Card is claimed; GitHub proof still needs to be connected.",
      label: "New signed-in user",
      nextPath: "/connect-github",
      nextText: "Connect GitHub",
      stage: "new-user",
    };
  }

  if (!workflow.published) {
    return {
      description: "GitHub is connected; card sources are selected in a private draft.",
      label: "Connected draft",
      nextPath: "/repos",
      nextText: "Customize card",
      stage: "connected-draft",
    };
  }

  return {
    description: "Builder owns a live, shareable PRBar card.",
    label: "Published owner",
    nextPath: "/profile",
    nextText: "Share PRBar card",
    stage: "published-owner",
  };
}

function shortProfilePath(profile: ProfileState) {
  return `/${profile.link.replace(/^https?:\/\//, "").replace(/^prbar\.dev\/?/, "") || "maya"}`;
}

function fullProfileLink(profile: ProfileState) {
  return `https://${profile.link.replace(/^https?:\/\//, "")}`;
}

function escapeHtml(value: string) {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

function escapeHtmlAttribute(value: string) {
  return escapeHtml(value)
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function embedSnippet(profile: ProfileState) {
  return `<a href="${escapeHtmlAttribute(fullProfileLink(profile))}" data-prbar-card="${escapeHtmlAttribute(profile.handle)}">${escapeHtml(profile.name)}'s PRBar card</a>`;
}

function builderCardSvg(profile: ProfileState, metrics: ReturnType<typeof sourceMetrics>) {
  const escape = escapeHtmlAttribute;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="960" height="540" viewBox="0 0 960 540" role="img" aria-label="${escape(profile.name)} PRBar card">
  <rect width="960" height="540" rx="36" fill="#10141f"/>
  <rect x="56" y="56" width="104" height="104" rx="18" fill="#19b394"/>
  <text x="108" y="122" text-anchor="middle" fill="#061611" font-family="Inter, Arial, sans-serif" font-size="34" font-weight="900">${escape(profile.initials)}</text>
  <text x="192" y="84" fill="#19b394" font-family="Inter, Arial, sans-serif" font-size="24" font-weight="900">${escape(profile.handle.toUpperCase())}</text>
  <text x="192" y="134" fill="#f8fafc" font-family="Inter, Arial, sans-serif" font-size="56" font-weight="900">${escape(profile.name)}</text>
  <text x="192" y="178" fill="#cbd5e1" font-family="Inter, Arial, sans-serif" font-size="25" font-weight="700">${escape(profile.title)}</text>
  <text x="56" y="250" fill="#f8fafc" font-family="Inter, Arial, sans-serif" font-size="34" font-weight="900">42 PRs · 4 releases · ${metrics.attached} apps shipped</text>
  <text x="56" y="296" fill="#94a3b8" font-family="Inter, Arial, sans-serif" font-size="24" font-weight="700">Proof from selected GitHub repos, releases, app updates, and public receipts.</text>
  <g transform="translate(56 350)">
    <rect width="250" height="104" rx="18" fill="#263142"/>
    <text x="28" y="45" fill="#f8fafc" font-family="Inter, Arial, sans-serif" font-size="34" font-weight="900">42</text>
    <text x="28" y="78" fill="#cbd5e1" font-family="Inter, Arial, sans-serif" font-size="22" font-weight="700">merged PRs</text>
    <rect x="300" width="250" height="104" rx="18" fill="#263142"/>
    <text x="328" y="45" fill="#f8fafc" font-family="Inter, Arial, sans-serif" font-size="34" font-weight="900">4</text>
    <text x="328" y="78" fill="#cbd5e1" font-family="Inter, Arial, sans-serif" font-size="22" font-weight="700">releases</text>
    <rect x="600" width="250" height="104" rx="18" fill="#263142"/>
    <text x="628" y="45" fill="#f8fafc" font-family="Inter, Arial, sans-serif" font-size="34" font-weight="900">${metrics.attached}</text>
    <text x="628" y="78" fill="#cbd5e1" font-family="Inter, Arial, sans-serif" font-size="22" font-weight="700">shipped apps</text>
  </g>
  <text x="56" y="504" fill="#19b394" font-family="Inter, Arial, sans-serif" font-size="22" font-weight="900">${escape(fullProfileLink(profile))}</text>
</svg>`;
}

function saveLocal<T>(key: string, value: T) {
  window.localStorage.setItem(key, JSON.stringify(value));
}

export default function PrototypeApp() {
  const [mounted, setMounted] = useState(false);
  const [route, setRoute] = useState("/home");
  const [session, setSession] = useState<SessionState>({ isAuthenticated: false, githubConnected: false });
  const [profile, setProfile] = useState<ProfileState>(defaultProfile);
  const [workflow, setWorkflow] = useState<WorkflowState>(defaultWorkflow);
  const [publicPreview, setPublicPreview] = useState(false);

  useEffect(() => {
    setMounted(true);
    setRoute(currentRoute());
    setSession(readStored<SessionState>(sessionKey, { isAuthenticated: false, githubConnected: false }));
    setProfile(normalizeProfile(readStored<Partial<ProfileState> | null>(profileKey, null)));
    setWorkflow(normalizeWorkflow(readStored<Partial<WorkflowState> | null>(workflowKey, null)));
    document.body.classList.add("toc-collapsed");

    const syncRoute = () => setRoute(currentRoute());
    window.addEventListener("hashchange", syncRoute);
    window.addEventListener("popstate", syncRoute);
    return () => {
      window.removeEventListener("hashchange", syncRoute);
      window.removeEventListener("popstate", syncRoute);
    };
  }, []);

  const navigate = useCallback((path: string) => {
    if (!isProofRoute(path)) setPublicPreview(false);
    window.history.pushState({}, "", path);
    setRoute(path);
    window.scrollTo({ top: 0 });
  }, []);

  const togglePublicPreview = useCallback((value: boolean) => {
    if (value) {
      window.scrollTo({ top: 0 });
      window.requestAnimationFrame(() => window.scrollTo({ top: 0 }));
    }
    setPublicPreview(value);
  }, []);

  const updateSession = useCallback((next: Partial<SessionState>) => {
    setSession((current) => {
      const updated = { ...current, ...next };
      saveLocal(sessionKey, updated);
      return updated;
    });
  }, []);

  const resetSession = useCallback(() => {
    window.localStorage.removeItem(sessionKey);
    setSession({ isAuthenticated: false, githubConnected: false });
    setPublicPreview(false);
  }, []);

  const updateWorkflow = useCallback((updater: (current: WorkflowState) => WorkflowState) => {
    setWorkflow((current) => {
      const updated = normalizeWorkflow(updater(structuredClone(current)));
      saveLocal(workflowKey, updated);
      return updated;
    });
  }, []);

  const publishWorkflow = useCallback(() => {
    updateWorkflow((current) => ({
      ...current,
      published: true,
      sourcesReviewed: true,
      draftDirty: false,
      publicSources: structuredClone(current.sources),
      shareFeedback: current.published ? "Published updates to the public PRBar card." : "",
      shareOutput: current.shareOutput,
    }));
  }, [updateWorkflow]);

  const saveProfile = useCallback((next: Partial<ProfileState>) => {
    const updated = normalizeProfile(next);
    saveLocal(profileKey, updated);
    setProfile(updated);
  }, []);

  useEffect(() => {
    if (!mounted || route !== "/logout") return;
    resetSession();
  }, [mounted, resetSession, route]);

  if (!mounted) {
    return <div className="loading">Loading PRBar prototype...</div>;
  }

  const publicPreviewActive = publicPreview && isProofRoute(route);
  const productState = productStateFor(session, workflow, publicPreviewActive);

  return (
    <Shell
      navigate={navigate}
      profile={profile}
      productState={productState}
      publicPreview={publicPreviewActive}
      resetSession={resetSession}
      route={route}
      session={session}
      setPublicPreview={togglePublicPreview}
    >
      {route === "/home" && <HomePage navigate={navigate} productState={productState} profile={profile} session={session} workflow={workflow} />}
      {route === "/signup" && <AuthPage mode="signup" navigate={navigate} profile={profile} saveProfile={saveProfile} updateSession={updateSession} />}
      {(route === "/signin" || route === "/login") && <AuthPage mode="signin" navigate={navigate} profile={profile} saveProfile={saveProfile} updateSession={updateSession} />}
      {route === "/logout" && <LogoutPage navigate={navigate} />}
      {route === "/onboarding" && <OnboardingPage navigate={navigate} />}
      {route === "/connect-github" && <ConnectGithubPage navigate={navigate} session={session} updateSession={updateSession} />}
      {isProofRoute(route) && (
        <ProfilePage
          navigate={navigate}
          productState={productState}
          profile={profile}
          publicPreview={publicPreviewActive}
          publishWorkflow={publishWorkflow}
          route={route}
          session={session}
          setPublicPreview={togglePublicPreview}
          updateWorkflow={updateWorkflow}
          workflow={workflow}
        />
      )}
      {route === "/user" && (
        session.isAuthenticated ? (
          <UserProfilePage navigate={navigate} productState={productState} profile={profile} session={session} workflow={workflow} resetSession={resetSession} />
        ) : (
          <OwnerGatePage kind="profile" navigate={navigate} profile={profile} />
        )
      )}
      {route === "/edit-profile" && (
        session.isAuthenticated ? (
          <EditProfilePage navigate={navigate} profile={profile} saveProfile={saveProfile} />
        ) : (
          <OwnerGatePage kind="edit" navigate={navigate} profile={profile} />
        )
      )}
      {route === "/repos" && (
        <ReposPage
          navigate={navigate}
          publishWorkflow={publishWorkflow}
          productState={productState}
          session={session}
          updateWorkflow={updateWorkflow}
          workflow={workflow}
        />
      )}
      {route === "/account" && (
        session.isAuthenticated ? (
          <AccountPage navigate={navigate} resetSession={resetSession} session={session} profile={profile} />
        ) : (
          <OwnerGatePage kind="account" navigate={navigate} profile={profile} />
        )
      )}
    </Shell>
  );
}

type NavigateProps = {
  navigate: (path: string) => void;
};

function Shell({
  children,
  navigate,
  profile,
  productState,
  publicPreview,
  resetSession,
  route,
  session,
  setPublicPreview,
}: NavigateProps & {
  children: React.ReactNode;
  profile: ProfileState;
  productState: ProductState;
  publicPreview: boolean;
  resetSession: () => void;
  route: string;
  session: SessionState;
  setPublicPreview: (value: boolean) => void;
}) {
  const activeSection = sectionFor(route, session);
  const [workflowMapOpen, setWorkflowMapOpen] = useState(false);
  const navRoutes = session.isAuthenticated ? signedInRoutes : signedOutRoutes;

  const logout = () => {
    resetSession();
    navigate("/home");
  };

  return (
    <div className="mockup-shell" data-product-state={productState.stage}>
      <div className="mockup-main">
        <header className="topbar">
          <button
            className="toc-toggle"
            aria-controls="workflow-map"
            aria-expanded={workflowMapOpen}
            aria-label={workflowMapOpen ? "Close setup map" : "Setup map"}
            onClick={() => setWorkflowMapOpen((value) => !value)}
            type="button"
          >
            <span />
            <span />
          </button>
          <button className="brand" type="button" onClick={() => navigate("/home")} aria-label="PRBar home">
            <span>PR</span>
            <strong>PRBar</strong>
          </button>
          <nav className="nav" aria-label="Primary navigation">
            {navRoutes.map((item) => (
              <button
                className={activeSection === item.path ? "active" : ""}
                data-section={item.path}
                key={item.path}
                onClick={() => navigate(item.path)}
                type="button"
              >
                {item.label}
              </button>
            ))}
          </nav>
          <div className="topbar-account" data-auth-state={session.isAuthenticated ? "signed-in" : "signed-out"}>
            {session.isAuthenticated && publicPreview && isProofRoute(route) ? (
              <>
                <span className="topbar-preview-pill">Public preview</span>
                <button className="topbar-link" data-preview-action="exit" onClick={() => setPublicPreview(false)} type="button">
                  Exit preview
                </button>
              </>
            ) : session.isAuthenticated ? (
              <>
                <button className="topbar-profile" onClick={() => navigate("/user")} type="button">
                  <span className="avatar mini">{profile.initials}</span>
                  <b>Setup</b>
                </button>
                <button className="topbar-link" onClick={() => navigate(session.githubConnected ? "/repos" : "/connect-github")} type="button">
                  {session.githubConnected ? "GitHub connected" : "Connect GitHub"}
                </button>
                <button className="topbar-link" data-auth-action="logout" onClick={logout} type="button">
                  Log out
                </button>
              </>
            ) : (
              <>
                <button className="topbar-link" onClick={() => navigate("/signin")} type="button">
                  Sign in
                </button>
                <button className="topbar-action" onClick={() => navigate("/signup")} type="button">
                  Claim your card
                </button>
              </>
            )}
          </div>
        </header>
        {workflowMapOpen && (
          <section className="workflow-map-panel" id="workflow-map" aria-label="PRBar workflow map">
            <div>
              <span>Workflow map</span>
              <b>Connect GitHub -&gt; customize what counts -&gt; publish and share your PRBar card.</b>
            </div>
            <div className="workflow-map-actions">
              <button onClick={() => navigate(session.isAuthenticated ? "/user" : "/signup")} type="button">Start setup</button>
              <button onClick={() => navigate("/profile")} type="button">View card</button>
              <button onClick={() => navigate(session.githubConnected ? "/repos" : "/connect-github")} type="button">{session.githubConnected ? "Customize sources" : "Connect GitHub"}</button>
              <button onClick={() => setWorkflowMapOpen(false)} type="button">Close</button>
            </div>
          </section>
        )}
        <main>{children}</main>
        <footer className="app-version-footer" aria-label="PRBar app version">
          PRBar v{appVersionDisplayValue()}
        </footer>
      </div>
    </div>
  );
}

function HomePage({
  navigate,
  productState,
  profile,
  session,
  workflow,
}: NavigateProps & {
  productState: ProductState;
  profile: ProfileState;
  session: SessionState;
  workflow: WorkflowState;
}) {
  const [cardSide, setCardSide] = useState<"front" | "back">("front");
  const flipped = cardSide === "back";

  return (
    <>
      <section className={`home-concept-hero${session.isAuthenticated ? " signed-in" : ""}`}>
        <div className="home-concept-copy">
          <p className="home-proof-pill">
            <span aria-hidden="true">✣</span>
            Your work. Proven.
          </p>
          <h1>PRBar is the new resume for AI-native <span className="headline-accent">builders.</span></h1>
          <p className="lede">Connect GitHub and PRBar turns shipped work into a beautiful, proof-backed card that highlights what you ship.</p>
          <p className="hero-proof-line">Great defaults. Fully customizable.</p>
          <div className="home-cta-row">
            <button className="primary github-cta" onClick={() => navigate(productState.nextPath)} type="button">
              <GitHubMark />
              {productState.stage === "signed-out" ? "Connect GitHub" : productState.nextText}
            </button>
            <button className="preview-link" onClick={() => navigate("/profile")} type="button">Preview card <span aria-hidden="true">→</span></button>
          </div>
          <p className="home-trust-note"><span aria-hidden="true">◆</span> Client-side only. Your code never leaves your device.</p>
          <p className="home-permission-note">Public repos by default. Private repos only if you select them.</p>
        </div>
        <HomeFlipCard
          flipped={flipped}
          navigate={navigate}
          profile={profile}
          setCardSide={setCardSide}
        />
      </section>
      <HomeProofPath navigate={navigate} productState={productState} />
      {session.isAuthenticated && (
        <SignedInHomePanel
          navigate={navigate}
          productState={productState}
          profile={profile}
          session={session}
          workflow={workflow}
        />
      )}
      <section className="home-doorway" aria-label="PRBar product preview">
        <div className="doorway-intro">
          <h2>One card with proof behind it.</h2>
          <p>PRBar stays useful before any network exists: claim the card, connect GitHub, keep the defaults or tune the sources, and share a resume people can inspect.</p>
        </div>
        <div className="doorway-grid">
          <button className="doorway-panel" onClick={() => navigate("/profile")} type="button">
            <span>01 / PRBar card</span>
            <strong>Beautiful by default.</strong>
            <p>A compact share card works in bios, resumes, launches, intros, and investor updates.</p>
          </button>
          <button className="doorway-panel" onClick={() => navigate("/repos")} type="button">
            <span>02 / GitHub proof</span>
            <strong>Credible without extra work.</strong>
            <p>PR velocity, releases, checks, app updates, and receipts come from selected GitHub sources.</p>
          </button>
          <button className="doorway-panel" onClick={() => navigate("/repos")} type="button">
            <span>03 / Customization</span>
            <strong>Simple controls when needed.</strong>
            <p>Defaults get the card live quickly; source selection and redaction keep private work private.</p>
          </button>
        </div>
      </section>
      <section className="proof-manifesto">No feed. No threads. No productivity theater. Just your card and the proof behind it.</section>
    </>
  );
}

function SignedInHomePanel({
  navigate,
  productState,
  profile,
  session,
  workflow,
}: NavigateProps & {
  productState: ProductState;
  profile: ProfileState;
  session: SessionState;
  workflow: WorkflowState;
}) {
  const metrics = sourceMetrics(workflow);
  const nextAction = !session.githubConnected
    ? ["Connect GitHub", "/connect-github"]
    : workflow.published
      ? ["Share PRBar card", "/profile"]
      : ["Review sources", "/repos"];

  return (
    <section className="signed-in-home-panel owner-home-panel" aria-label="Signed-in owner view">
      <div>
        <span>Signed-in owner view</span>
        <h2>Card workspace for {profile.name}.</h2>
        <p>{productState.description} Keep moving from this private setup view into source controls, profile edits, publishing, and public preview.</p>
      </div>
      <div className="signed-in-home-grid">
        <article>
          <span>Current state</span>
          <b>{productState.label}</b>
          <p>{session.githubConnected ? `${metrics.counted} selected sources, ${metrics.attached} attached apps, ${metrics.hidden} private names hidden.` : "Card claimed. GitHub proof is not connected yet."}</p>
        </article>
        <article>
          <span>PRBar card</span>
          <b>{shortProfilePath(profile)}</b>
          <p>The card is the portable resume link; proof details open behind it when someone wants context.</p>
        </article>
        <article>
          <span>Public status</span>
          <b>{workflow.published ? "Live" : "Draft"}</b>
          <p>{workflow.published ? "Signed-out visitors can inspect the proof artifact." : "Publish after source choices look right."}</p>
        </article>
      </div>
      <div className="action-row small">
        <button className="primary" onClick={() => navigate(nextAction[1])} type="button">{nextAction[0]}</button>
        <button className="secondary light" onClick={() => navigate("/user")} type="button">Setup checklist</button>
        <button className="secondary light" onClick={() => navigate("/profile")} type="button">Preview card</button>
        <button className="secondary light" onClick={() => navigate("/account")} type="button">Account controls</button>
      </div>
    </section>
  );
}

function HomeProofPath({ navigate, productState }: NavigateProps & { productState: ProductState }) {
  const activeStep = (() => {
    if (productState.stage === "signed-out" || productState.stage === "new-user") return "connect";
    if (productState.stage === "connected-draft") return "choose";
    if (productState.stage === "published-owner") return "publish";
    if (productState.stage === "public-prospect" && productState.nextPath === "/profile") return "publish";
    return "connect";
  })();
  const steps = [
    ["connect", "01", "Connect GitHub", "/connect-github"],
    ["choose", "02", "Customize", "/repos"],
    ["publish", "03", "Publish & share", "/profile"],
  ] as const;

  return (
    <section className="home-proof-path" aria-label="Path to PRBar card">
      {steps.map(([key, number, label, path]) => (
        <button
          className={key === activeStep ? "active" : ""}
          key={key}
          onClick={() => navigate(path)}
          type="button"
        >
          <span className="home-step-icon"><StepIcon step={key} /></span>
          <small>{number}</small>
          <b>{label}</b>
          <em>{key === "connect" ? "Analyze selected GitHub work locally." : key === "choose" ? "Fine-tune layout, metrics, and style." : "One link. Always up to date."}</em>
        </button>
      ))}
    </section>
  );
}

function GitHubMark() {
  return (
    <svg aria-hidden="true" viewBox="0 0 24 24">
      <path d="M12 2.3A9.7 9.7 0 0 0 8.9 21c.48.09.66-.2.66-.46v-1.7c-2.68.58-3.24-1.15-3.24-1.15-.44-1.12-1.08-1.42-1.08-1.42-.88-.6.07-.59.07-.59.98.07 1.5 1 1.5 1 .86 1.48 2.27 1.05 2.82.8.09-.63.34-1.05.61-1.29-2.14-.24-4.4-1.07-4.4-4.77 0-1.05.38-1.91 1-2.59-.1-.24-.43-1.22.1-2.55 0 0 .82-.26 2.67.99A9.25 9.25 0 0 1 12 6.94c.82 0 1.64.11 2.41.33 1.85-1.25 2.66-.99 2.66-.99.54 1.33.2 2.31.1 2.55.63.68 1 1.54 1 2.59 0 3.71-2.26 4.53-4.41 4.77.35.3.66.89.66 1.8v2.66c0 .26.18.56.67.46A9.7 9.7 0 0 0 12 2.3Z" fill="currentColor" />
    </svg>
  );
}

function StepIcon({ step }: { step: "connect" | "choose" | "publish" }) {
  if (step === "connect") {
    return <GitHubMark />;
  }

  if (step === "choose") {
    return (
      <svg aria-hidden="true" viewBox="0 0 24 24">
        <path d="M4 7h8M16 7h4M10 17h10M4 17h2" fill="none" stroke="currentColor" strokeLinecap="round" strokeWidth="2" />
        <circle cx="14" cy="7" r="2" fill="none" stroke="currentColor" strokeWidth="2" />
        <circle cx="8" cy="17" r="2" fill="none" stroke="currentColor" strokeWidth="2" />
      </svg>
    );
  }

  return (
    <svg aria-hidden="true" viewBox="0 0 24 24">
      <path d="M12 16V4m0 0 4.5 4.5M12 4 7.5 8.5M5 14v4.5A1.5 1.5 0 0 0 6.5 20h11a1.5 1.5 0 0 0 1.5-1.5V14" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" />
    </svg>
  );
}

function MiniProofBars({ tone, values }: { tone: "blue" | "gold" | "green"; values: number[] }) {
  return (
    <div className={`mini-proof-bars ${tone}`} aria-hidden="true">
      {values.map((value, index) => <i key={`${tone}-${index}`} style={{ height: `${value}%` }} />)}
    </div>
  );
}

function HomeFlipCard({
  flipped,
  navigate,
  profile,
  setCardSide,
}: NavigateProps & {
  flipped: boolean;
  profile: ProfileState;
  setCardSide: (side: "front" | "back") => void;
}) {
  return (
    <aside className={`builder-link-card-wrap ${flipped ? "flipped" : ""}`} data-builder-link-card aria-label="Interactive PRBar Card">
      <div className="builder-link-stage">
        <div className="builder-link-ghost hero-card-backdrop" aria-hidden="true">
          <div className="backdrop-section">
            <span>Top languages</span>
            {[
              ["TypeScript", "45%"],
              ["Python", "20%"],
              ["Go", "15%"],
              ["Swift", "10%"],
            ].map(([label, value]) => (
              <p key={label}><b>{label}</b><i style={{ width: value }} /><em>{value}</em></p>
            ))}
          </div>
          <div className="backdrop-section">
            <span>Top repos</span>
            {["sideproject-radar", "radar-ios", "launch-notes"].map((repo, index) => (
              <p key={repo}><b>{repo}</b><em>{["42 PRs", "9 PRs", "4 releases"][index]}</em></p>
            ))}
          </div>
          <strong>Built with proof by builders</strong>
        </div>
        <div className="builder-link-ghost second" aria-hidden="true" />
        <div className="builder-link-flip">
          <section className="builder-link-face builder-link-front" aria-hidden={flipped}>
            <span className="builder-link-glare" aria-hidden="true" />
            <div className="builder-link-identity">
              <div className="builder-profile-lockup">
                <div className="builder-avatar-orb"><span>{profile.initials}</span><i /></div>
                <div>
                  <span>Front: portable card</span>
                  <h3>{profile.name}</h3>
                  <em>{shortProfilePath(profile)}</em>
                </div>
              </div>
              <div className="builder-live-pill"><i />Live</div>
            </div>
            <p>{profile.title}. A compact proof link for bios, resumes, intros, and launch notes.</p>
            <div className="builder-link-chart" aria-label="Selected GitHub proof summary">
              {[34, 58, 42, 76, 64, 100, 82].map((value) => <i key={value} style={{ height: `${value}%` }} />)}
            </div>
            <div className="builder-link-stats">
              <div>
                <span>PR velocity</span>
                <b>8.6/day</b>
                <MiniProofBars tone="green" values={[38, 48, 55, 42, 68, 52, 82]} />
                <em>+24% vs 30 days</em>
              </div>
              <div>
                <span>Releases</span>
                <b>4</b>
                <MiniProofBars tone="blue" values={[28, 20, 36, 31, 58, 46, 72]} />
                <em>4 tagged ships</em>
              </div>
              <div>
                <span>Shipped apps</span>
                <b>{builder.stats.apps}</b>
                <MiniProofBars tone="gold" values={[35, 44, 30, 54, 72, 48, 66]} />
                <em>public proof</em>
              </div>
            </div>
            <button className="builder-link-card-cta" onClick={() => setCardSide("back")} tabIndex={flipped ? -1 : 0} type="button">Flip to proof snapshot</button>
          </section>
          <section className="builder-link-face builder-link-back" aria-hidden={!flipped}>
            <span className="builder-link-glare" aria-hidden="true" />
            <div className="builder-link-identity">
              <div>
                <span>Back: GitHub-backed proof</span>
                <h3>Open proof details</h3>
              </div>
              <div className="avatar">{profile.initials}</div>
            </div>
            <p>One current receipt, one shipped app, and one path into the proof behind the card.</p>
            <div className="builder-link-list">
              <button onClick={() => navigate("/receipt")} tabIndex={flipped ? 0 : -1} type="button">
                <span><strong>{release.title}</strong><em>{release.facts.slice(0, 2).join(" · ")}</em></span>
                <b>Receipt</b>
              </button>
              <button onClick={() => navigate("/project")} tabIndex={flipped ? 0 : -1} type="button">
                <span><strong>{apps[0].name}</strong><em>{apps[0].status} · app proof</em></span>
                <b>App</b>
              </button>
              <button onClick={() => navigate("/profile")} tabIndex={flipped ? 0 : -1} type="button">
                <span><strong>{profile.name}&apos;s PRBar card</strong><em>Receipts, apps, timeline</em></span>
                <b>Full</b>
              </button>
            </div>
            <button className="builder-link-card-cta light" onClick={() => navigate("/profile")} tabIndex={flipped ? 0 : -1} type="button">Open full card</button>
          </section>
        </div>
        <div className="hero-card-arrows" aria-label="Card preview controls">
          <button aria-label="Show card front" onClick={() => setCardSide("front")} type="button">
            <svg aria-hidden="true" viewBox="0 0 24 24">
              <path d="m14.5 6-6 6 6 6" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.4" />
            </svg>
          </button>
          <button aria-label="Show proof back" onClick={() => setCardSide("back")} type="button">
            <svg aria-hidden="true" viewBox="0 0 24 24">
              <path d="m9.5 6 6 6-6 6" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.4" />
            </svg>
          </button>
        </div>
      </div>
      <div className="builder-link-controls" aria-label="PRBar card side controls">
        <button aria-pressed={!flipped} className={!flipped ? "active" : ""} data-card-side="front" onClick={() => setCardSide("front")} type="button">Front: Card</button>
        <button aria-pressed={flipped} className={flipped ? "active" : ""} data-card-side="back" onClick={() => setCardSide("back")} type="button">Back: Proof</button>
      </div>
    </aside>
  );
}

function AuthPage({
  mode,
  navigate,
  profile,
  saveProfile,
  updateSession,
}: NavigateProps & {
  mode: "signin" | "signup";
  profile: ProfileState;
  saveProfile: (next: Partial<ProfileState>) => void;
  updateSession: (next: Partial<SessionState>) => void;
}) {
  const signup = mode === "signup";
  const [handle, setHandle] = useState(profile.handle);
  const [name, setName] = useState(profile.name);
  const submit = () => {
    if (signup) {
      const cleanHandle = (handle.trim() || profile.handle).replace(/^@+/, "");
      const normalizedHandle = `@${cleanHandle}`;
      saveProfile({
        ...profile,
        handle: normalizedHandle,
        link: linkFromHandle(cleanHandle),
        name,
      });
    }
    updateSession({ isAuthenticated: true, githubConnected: false });
    navigate(signup ? "/connect-github" : "/user");
  };

  return (
    <section className="auth-layout">
      <div className="auth-copy">
        <p className="eyebrow">{signup ? "Claim your card" : "Welcome back"}</p>
        <h1>{signup ? "Start with your resume card." : "Sign in to manage your PRBar card."}</h1>
        <p>{signup ? "Reserve your card, connect GitHub, and keep the defaults or customize which proof appears." : "Log in to reach your card, GitHub connection, account controls, and logout state."}</p>
        <SetupStepper active={signup ? "/signup" : "/profile"} />
      </div>
      <form className="auth-panel">
        <h2>{signup ? "Create your PRBar account" : "Sign in"}</h2>
        <label>Email<input type="email" defaultValue="maya@example.com" /></label>
        <label>Password<input type="password" defaultValue="builderproof" /></label>
        {signup && (
          <>
            <label>Name<input value={name} onChange={(event) => setName(event.target.value)} /></label>
            <label>Builder handle<input value={handle} onChange={(event) => setHandle(event.target.value)} /></label>
          </>
        )}
        <button className="primary wide" data-auth-action={signup ? "signup" : "login"} onClick={submit} type="button">
          {signup ? "Continue to GitHub" : "Sign in"}
        </button>
        <p>{signup ? "Already claimed a card?" : "Need a PRBar card?"} <button type="button" onClick={() => navigate(signup ? "/signin" : "/signup")}>{signup ? "Sign in" : "Create account"}</button></p>
      </form>
    </section>
  );
}

function OnboardingPage({ navigate }: NavigateProps) {
  return (
    <>
      <section className="page-hero">
        <p className="eyebrow">Onboarding</p>
        <h1>Publish your PRBar card in three moves.</h1>
        <p>PRBar keeps setup narrow: connect GitHub, customize what counts, then publish and share a proof-backed resume card.</p>
        <SetupStepper active="/connect-github" />
        <div className="action-row">
          <button className="primary" onClick={() => navigate("/connect-github")} type="button">Connect GitHub</button>
          <button className="secondary light" onClick={() => navigate("/profile")} type="button">Preview card</button>
        </div>
      </section>
      <section className="workflow-path-panel" aria-label="Solo PRBar card workflow">
        <span>Solo-user path</span>
        <h2>Connect GitHub -&gt; customize what counts -&gt; publish and share your PRBar card.</h2>
        <p>Every step stays local in this prototype: mock auth, mock GitHub connection, persisted source choices, and share feedback are stored in this browser.</p>
      </section>
    </>
  );
}

function ConnectGithubPage({ navigate, session, updateSession }: NavigateProps & { session: SessionState; updateSession: (next: Partial<SessionState>) => void }) {
  const connect = () => {
    updateSession({ isAuthenticated: true, githubConnected: true });
    navigate("/repos");
  };
  const connected = session.githubConnected;

  return (
    <section className="connect-layout">
      <div className="connect-copy">
        <p className="eyebrow">{connected ? "GitHub connected" : "Connect GitHub"}</p>
        <h1>{connected ? "GitHub proof is ready to review." : "Bring in the facts, then choose what counts."}</h1>
        <p>{connected ? "Selected repo access is active. The next step is choosing what powers the public PRBar card." : "PRBar reads release tags, merged PR metadata, checks, and selected repo names. You decide which sources appear publicly."}</p>
        <SetupStepper active={connected ? "/repos" : "/connect-github"} />
      </div>
      <aside className="connect-panel">
        <h2>{connected ? "github.com/maya connected" : "github.com/maya"}</h2>
        <p>{connected ? "Release tags, merged PR metadata, checks, and candidate repos are available in the private source review." : "Selected repo access requested. Private repositories remain hidden until you choose to count or reveal them."}</p>
        <div className="permission-list">
          <span>Release tags</span>
          <span>Merged PR metadata</span>
          <span>Status checks</span>
          <span>Selected repo names</span>
        </div>
        <p className="trust-note">GitHub proof means imported PR, release, tag, timestamp, and check metadata. Builder notes and app descriptions add context, but cannot change imported facts.</p>
        <div className="github-source-preview" aria-label="GitHub source preview">
          <span>{connected ? "Ready for source review" : "Review after authorize"}</span>
          <b>4 candidate sources found</b>
          <p>PRBar will start in draft. You decide which repos count, which names stay hidden, and which apps attach to the card.</p>
          <div>
            {sources.slice(0, 3).map((source) => (
              <article key={source.name}>
                <code>{source.visibility === "private" ? "private repo" : source.name}</code>
                <span>{source.activity}</span>
                <em>{source.status === "excluded" ? "excluded by default" : source.visibility === "private" ? "name hidden by default" : "ready to count"}</em>
              </article>
            ))}
          </div>
        </div>
        {connected ? (
          <button className="primary wide" onClick={() => navigate("/repos")} type="button">Open Sources & Privacy</button>
        ) : (
          <button className="primary wide" data-auth-action="connect-github" onClick={connect} type="button">
            Authorize and choose sources
          </button>
        )}
      </aside>
    </section>
  );
}

function LogoutPage({ navigate }: NavigateProps) {
  return (
    <section className="auth-layout">
      <div className="auth-copy">
        <p className="eyebrow">Signed out</p>
        <h1>You&apos;re signed out.</h1>
        <p>The local mock session has been cleared. The public PRBar card remains shareable, and account controls are one sign-in away.</p>
      </div>
      <aside className="auth-panel">
        <h2>Return to PRBar</h2>
        <button className="primary wide" onClick={() => navigate("/signin")} type="button">Sign in again</button>
        <button className="secondary light wide" onClick={() => navigate("/home")} type="button">Back home</button>
      </aside>
    </section>
  );
}

function OwnerGatePage({ kind, navigate, profile }: NavigateProps & { kind: "account" | "edit" | "profile"; profile: ProfileState }) {
  const gates = {
    account: ["Account locked", "Sign in to manage account permissions.", "Account permissions, exports, private source defaults, and deletion controls stay behind the owner session."],
    edit: ["Owner tools locked", "Sign in to edit this card.", "The public PRBar card can stay visible while profile copy, handle, availability, and source-backed settings stay owner-only."],
    profile: ["Owner profile locked", "Sign in to manage this PRBar card.", "Visitors can inspect the public card. Owners sign in to edit profile copy, connect GitHub, choose sources, and publish updates."],
  } as const;
  const gate = gates[kind];

  return (
    <section className="auth-layout owner-gate-layout">
      <div className="auth-copy">
        <p className="eyebrow">{gate[0]}</p>
        <h1>{gate[1]}</h1>
        <p>{gate[2]}</p>
        <div className="action-row">
          <button className="primary" onClick={() => navigate("/signin")} type="button">Sign in</button>
          <button className="secondary light" onClick={() => navigate("/profile")} type="button">View public card</button>
        </div>
      </div>
      <aside className="owner-gate-card">
        <span className="avatar xl">{profile.initials}</span>
        <h2>{profile.name}</h2>
        <p>{profile.handle} · {profile.link}</p>
        <button className="primary wide" onClick={() => navigate("/signup")} type="button">Claim your card</button>
      </aside>
    </section>
  );
}

function UserProfilePage({ navigate, productState, profile, resetSession, session, workflow }: NavigateProps & {
  productState: ProductState;
  profile: ProfileState;
  resetSession: () => void;
  session: SessionState;
  workflow: WorkflowState;
}) {
  const logout = () => {
    resetSession();
    navigate("/home");
  };
  const proofButtonLabel = workflow.published ? "View public card" : "Open card draft";
  const sessionMessage = !session.githubConnected
    ? "Connect GitHub to import release tags, merged PRs, and source proof."
    : workflow.published
      ? "Published PRBar card is live and ready to share."
      : "Draft PRBar card is ready to publish.";
  const gitHubActionLabel = session.githubConnected ? "Review GitHub sources" : "Connect GitHub";

  return (
    <section className="account-layout owner-dashboard-layout">
      <aside className="account-rail">
        <span className="avatar xl">{profile.initials}</span>
        <h2>{profile.name}</h2>
        <p>{profile.handle} · {profile.link}</p>
        <button className="primary wide" onClick={() => navigate("/profile")} type="button">{proofButtonLabel}</button>
      </aside>
      <div className="account-main">
        <div className="control-section-heading">
          <span>Card setup</span>
          <h1>Manage your PRBar card.</h1>
        </div>
        <div className="session-strip">
          <b>Signed in</b>
          <span>{sessionMessage}</span>
        </div>
        <StateStatusStrip productState={productState} session={session} workflow={workflow} />
        <WorkflowPath session={session} workflow={workflow} navigate={navigate} />
        <SetupChecklist session={session} workflow={workflow} />
        <div className="account-grid">
          <button onClick={() => navigate("/edit-profile")} type="button"><b>Edit profile</b><span>Name, handle, title, availability, and links.</span></button>
          <button onClick={() => navigate(session.githubConnected ? "/repos" : "/connect-github")} type="button"><b>{gitHubActionLabel}</b><span>{session.githubConnected ? "Tune selected sources, redaction, and app attachments." : "Import PRs, releases, checks, and selected repo names."}</span></button>
          <button onClick={() => navigate("/account")} type="button"><b>Account permissions</b><span>GitHub access, private source controls, and export settings.</span></button>
          <button onClick={() => navigate("/repos")} type="button"><b>Sources & Privacy</b><span>Choose what powers the public card.</span></button>
          <button data-auth-action="logout" onClick={logout} type="button"><b>Log out</b><span>Clear the local mock session and return home.</span></button>
        </div>
      </div>
    </section>
  );
}

function EditProfilePage({ navigate, profile, saveProfile }: NavigateProps & { profile: ProfileState; saveProfile: (next: Partial<ProfileState>) => void }) {
  const [draft, setDraft] = useState(profile);
  const update = (field: keyof ProfileState, value: string) => setDraft((current) => ({ ...current, [field]: value }));
  const save = () => {
    saveProfile(draft);
    navigate("/user");
  };

  return (
    <section className="account-layout">
      <aside className="account-rail">
        <span className="avatar xl">{profile.initials}</span>
        <h2>Public identity</h2>
        <p>This copy appears on the PRBar card and proof details.</p>
      </aside>
      <form className="account-main profile-edit-form" data-profile-form>
        <div className="control-section-heading">
          <span>Edit profile</span>
          <h1>Tune the public card.</h1>
        </div>
        <div className="profile-form-grid">
          <div className="profile-field-stack">
            <label>Name<input name="profile-name" value={draft.name} onChange={(event) => update("name", event.target.value)} /></label>
            <label>Handle<input name="profile-handle" value={draft.handle} onChange={(event) => update("handle", event.target.value)} /></label>
            <label>Proof link<input name="profile-link" value={draft.link} onChange={(event) => update("link", event.target.value)} /></label>
            <label>Title<input name="profile-title" value={draft.title} onChange={(event) => update("title", event.target.value)} /></label>
            <label>Availability<input name="profile-availability" value={draft.availability} onChange={(event) => update("availability", event.target.value)} /></label>
            <label>Builder note<textarea name="profile-note" value={draft.note} onChange={(event) => update("note", event.target.value)} /></label>
          </div>
          <aside className="profile-live-preview">
            <span>Public preview</span>
            <b>{draft.name}</b>
            <em>{draft.handle}</em>
            <p>{draft.title}</p>
            <strong>{draft.availability}</strong>
          </aside>
        </div>
        <div className="action-row">
          <button className="primary" data-profile-action="save" onClick={save} type="button">Save profile</button>
          <button className="secondary light" onClick={() => navigate("/profile")} type="button">Preview card</button>
        </div>
      </form>
    </section>
  );
}

function ReposPage({ navigate, productState, publishWorkflow, session, updateWorkflow, workflow }: NavigateProps & {
  publishWorkflow: () => void;
  productState: ProductState;
  session: SessionState;
  updateWorkflow: (updater: (current: WorkflowState) => WorkflowState) => void;
  workflow: WorkflowState;
}) {
  if (!session.githubConnected) {
    return (
      <section className="public-empty-state">
        <div>
          <p className="eyebrow">Sources & Privacy</p>
          <h1>Connect GitHub to choose sources.</h1>
          <p>Source controls stay private until the builder signs in and authorizes selected repository access.</p>
          <SetupStepper active="/connect-github" />
          <div className="action-row">
            <button className="primary" onClick={() => navigate("/connect-github")} type="button">Connect GitHub</button>
            <button className="secondary light" onClick={() => navigate("/signin")} type="button">Sign in</button>
          </div>
        </div>
        <aside className="empty-proof-card"><span>No source access</span><b>0 sources selected</b><p>PR velocity, releases, apps, and receipts appear after GitHub is connected.</p></aside>
      </section>
    );
  }

  const metrics = sourceMetrics(workflow);

  const setSource = (name: string, action: "attach" | "toggleHidden" | SourceMode) => {
    updateWorkflow((current) => {
      const state = current.sources[name];
      const source = sources.find((item) => item.name === name);
      if (!state || !source) return current;
      if (action === "attach") {
        state.attached = !state.attached;
        if (state.attached && state.mode === "excluded") state.mode = "included";
      } else if (action === "toggleHidden") {
        state.hidden = !state.hidden;
        if (state.hidden && state.mode === "included") state.mode = "redacted";
        if (!state.hidden && state.mode === "redacted") state.mode = "included";
      } else {
        state.mode = action;
        if (action === "excluded") {
          state.attached = false;
          state.hidden = true;
        }
        if (action === "redacted") state.hidden = true;
        if (action === "included" && source.visibility === "public") state.hidden = false;
      }
      current.sourcesReviewed = false;
      current.draftDirty = current.published;
      current.shareFeedback = current.published
        ? "Source changes saved to draft. Publish updates to refresh the public PRBar card."
        : "Source choices saved to draft. Review and publish when ready.";
      current.shareOutput = "";
      return current;
    });
  };

  return (
    <>
      <section className="page-hero control-hero">
        <div>
          <p className="eyebrow">Sources & Privacy</p>
          <h1>Customize what powers the card.</h1>
          <p>Only selected GitHub sources become public proof behind the PRBar card. Everything else stays private, redacted, or excluded.</p>
          <StateStatusStrip productState={productState} session={session} workflow={workflow} />
        </div>
        <div className="control-hero-stats" aria-label="Current PRBar card source summary">
          <div><span>Selected</span><b>{metrics.counted}</b><em>sources count</em></div>
          <div><span>Attached</span><b>{metrics.attached}</b><em>apps shown</em></div>
          <div><span>Private</span><b>{metrics.hidden}</b><em>names hidden</em></div>
          <div><span>Status</span><b>{workflow.published ? "Live" : "Draft"}</b><em>{workflow.published ? "share-ready" : "not public"}</em></div>
        </div>
      </section>
      <section className="control-room">
        <aside className="control-rail">
          <div className="control-status-card">
            <span>Connection</span>
            <b>GitHub connected</b>
            <p>Selected repo access. Release tags, PR metadata, and checks are available for approved sources only.</p>
          </div>
          <div className="control-status-card publish-status-card">
            <span>Publish status</span>
            <b>{workflow.published ? "PRBar card is live" : "Draft PRBar card"}</b>
            <p>{metrics.counted} sources power the card. {metrics.attached} attached apps. {metrics.excluded} excluded. {workflow.published ? "Share link ready." : "Publish when the public resume card should go live."}</p>
            {workflow.shareFeedback && <p className="share-feedback" data-share-feedback>{workflow.shareFeedback}</p>}
            {!workflow.sourcesReviewed && <p className="draft-warning">Review and confirm source choices before publishing.</p>}
            {workflow.draftDirty && <p className="draft-warning">Your live PRBar card is still public. These source changes are private until you publish updates.</p>}
            <button className="secondary light wide" data-source-action="confirm-review" onClick={() => updateWorkflow((current) => ({ ...current, sourcesReviewed: true, shareFeedback: "Source choices reviewed. PRBar card is ready to publish." }))} type="button">Confirm source choices</button>
            <button className="primary wide" data-proof-action={workflow.published ? "publish-updates" : "publish"} disabled={!workflow.sourcesReviewed} onClick={publishWorkflow} type="button">{workflow.published && workflow.draftDirty ? "Publish updates" : "Publish PRBar card"}</button>
            {workflow.published && (
              <>
                <button className="primary wide" data-proof-action="open-public" onClick={() => navigate("/profile")} type="button">Open public card</button>
                <button className="secondary light wide" data-proof-action="unpublish" onClick={() => updateWorkflow((current) => ({ ...current, published: false, publicSources: null, draftDirty: false, shareFeedback: "", shareOutput: "" }))} type="button">Return to draft</button>
              </>
            )}
          </div>
          <div className="control-status-card">
            <span>Public preview impact</span>
            <b>{metrics.counted} sources power the card</b>
            <p>{metrics.attached} attached apps, {metrics.hidden} private hidden, {metrics.excluded} excluded.</p>
          </div>
        </aside>
        <div className="control-workbench">
          <div className="control-section-heading">
            <span>Source matrix</span>
            <h2>Review sources.</h2>
            <p>Each source has count, app attachment, and privacy controls in one row.</p>
          </div>
          <div className="source-table">
            {sources.map((source) => {
              const state = workflow.sources[source.name];
              return (
                <article className="source-table-row" data-source-row={source.name} key={source.name}>
                  <div>
                    <h3>{source.name}</h3>
                    <p>{source.activity} / latest release {source.lastRelease}</p>
                  </div>
                  <span>{source.visibility}</span>
                  <b>{state.mode === "excluded" ? "Excluded" : state.hidden || state.mode === "redacted" ? "Hidden from public" : "Public name visible"}</b>
                  <em>{state.attached ? source.app : "No app attached"}</em>
                  <div className="repo-controls" aria-label={`${source.name} source controls`}>
                    <div className="source-mode-segment" aria-label={`${source.name} count mode`}>
                      <button className={state.mode === "included" ? "active" : ""} data-source-action="include" data-source-id={source.name} onClick={() => setSource(source.name, "included")} type="button">Include</button>
                      <button className={state.mode === "redacted" ? "active" : ""} data-source-action="redact" data-source-id={source.name} onClick={() => setSource(source.name, "redacted")} type="button">Redact</button>
                      <button className={state.mode === "excluded" ? "active" : ""} data-source-action="exclude" data-source-id={source.name} onClick={() => setSource(source.name, "excluded")} type="button">Exclude</button>
                    </div>
                    <div className="source-secondary-actions">
                      <button className={state.attached ? "active" : ""} data-source-action="attach" data-source-id={source.name} onClick={() => setSource(source.name, "attach")} type="button">{state.attached ? "Attached" : "Attach app"}</button>
                      <button className={state.hidden ? "active" : ""} data-source-action="privacy" data-source-id={source.name} onClick={() => setSource(source.name, "toggleHidden")} type="button">{state.hidden ? "Hidden from public" : "Reveal publicly"}</button>
                    </div>
                  </div>
                  <p className="repo-impact">{state.mode === "excluded" ? "Excluded from public proof, receipts, cards, and source counts." : state.hidden || state.mode === "redacted" ? "Visible to you here. Hidden from the public PRBar card while still counting selected proof." : source.publicImpact}</p>
                </article>
              );
            })}
          </div>
          <section className="attachment-editor-grid">
            <article className="receipt-editor-panel">
              <div className="control-section-heading">
                <span>Receipt editor</span>
                <h2>Edit latest receipt.</h2>
              </div>
              <p>Receipt editing lives with source controls because public context, redaction, and locked GitHub facts meet here.</p>
            </article>
          </section>
        </div>
      </section>
    </>
  );
}

function ProfilePage({
  navigate,
  productState,
  profile,
  publicPreview,
  publishWorkflow,
  route,
  session,
  setPublicPreview,
  updateWorkflow,
  workflow,
}: NavigateProps & {
  productState: ProductState;
  profile: ProfileState;
  publicPreview: boolean;
  publishWorkflow: () => void;
  route: ProofRoute;
  session: SessionState;
  setPublicPreview: (value: boolean) => void;
  updateWorkflow: (updater: (current: WorkflowState) => WorkflowState) => void;
  workflow: WorkflowState;
}) {
  const ownerView = session.isAuthenticated && !publicPreview;
  const draftMetrics = useMemo(() => sourceMetrics(workflow), [workflow]);
  const publicMetrics = useMemo(() => sourceMetrics(workflow, "public"), [workflow]);
  const metrics = ownerView ? draftMetrics : publicMetrics;
  const proofMetrics = ownerView && !workflow.draftDirty ? draftMetrics : publicMetrics;
  const aliasTarget = proofAliasTarget(route);

  useEffect(() => {
    if (!aliasTarget) return;
    const focusTarget = () => {
      const target = document.getElementById(aliasTarget);
      target?.scrollIntoView({ block: "start", behavior: "instant" });
      target?.focus({ preventScroll: true });
    };
    const frame = window.requestAnimationFrame(focusTarget);
    const timeout = window.setTimeout(focusTarget, 80);

    return () => {
      window.cancelAnimationFrame(frame);
      window.clearTimeout(timeout);
    };
  }, [aliasTarget]);

  if (!workflow.published) {
    if (session.isAuthenticated) {
      return (
        <DraftOwnerProofPage
          metrics={metrics}
          navigate={navigate}
          productState={productState}
          profile={profile}
          publishWorkflow={publishWorkflow}
          session={session}
          workflow={workflow}
        />
      );
    }

    return (
      <section className="public-empty-state">
        <div>
          <p className="eyebrow">Public PRBar card</p>
          <h1>PRBar card is not published yet.</h1>
          <p>{profile.name.split(/\s+/)[0]} has not made this PRBar card public. The owner can connect GitHub, customize sources, publish the card, then share the public link anywhere.</p>
          <StateStatusStrip productState={productState} publicArtifact />
          <SetupStepper active="/profile" />
          <div className="action-row">
            <button className="primary" onClick={() => navigate(session.isAuthenticated ? "/repos" : "/signup")} type="button">{session.isAuthenticated ? "Open card controls" : "Claim your card"}</button>
            <button className="secondary light" onClick={() => navigate(session.isAuthenticated ? "/user" : "/signin")} type="button">{session.isAuthenticated ? "Setup checklist" : "Sign in to publish"}</button>
          </div>
        </div>
        <aside className="empty-proof-card"><span>Waiting for proof</span><b>Draft only</b><p>No PRs, releases, apps, or receipts are public until the builder publishes.</p></aside>
      </section>
    );
  }

  const writeClipboard = async (value: string) => {
    try {
      if (!window.navigator.clipboard?.writeText) return false;
      await window.navigator.clipboard.writeText(value);
      return true;
    } catch {
      return false;
    }
  };

  const share = async (action: ShareAction) => {
    const outputs = {
      card: {
        feedback: "Copied card link",
        value: `${fullProfileLink(profile)}#builder-card`,
      },
      embed: {
        feedback: "Copied embed snippet",
        value: embedSnippet(profile),
      },
      image: {
        feedback: "Downloaded builder-card.svg",
        value: builderCardSvg(profile, proofMetrics),
      },
      proof: {
        feedback: `Copied full card link: ${fullProfileLink(profile)}`,
        value: fullProfileLink(profile),
      },
    } satisfies Record<ShareAction, { feedback: string; value: string }>;

    const output = outputs[action];
    let feedback = output.feedback;

    if (action === "image") {
      const blob = new Blob([output.value], { type: "image/svg+xml" });
      const url = window.URL.createObjectURL(blob);
      const anchor = document.createElement("a");
      anchor.href = url;
      anchor.download = "builder-card.svg";
      document.body.append(anchor);
      anchor.click();
      anchor.remove();
      window.URL.revokeObjectURL(url);
    } else {
      const copied = await writeClipboard(output.value);
      if (!copied) feedback = `${output.feedback} (copy ready)`;
    }

    updateWorkflow((current) => ({ ...current, shareFeedback: feedback, shareOutput: output.value }));
  };

  return (
    <>
      <section className="profile-hero proof-resume-hero">
        <div className="profile-main">
          <span className="avatar xl">{profile.initials}</span>
          <div>
            <p className="eyebrow">{workflow.published ? "Published PRBar card" : "PRBar card"}</p>
            <h1>{profile.name}</h1>
            <p className="profile-handle-line">{profile.handle} · {profile.link}</p>
            <p>{profile.title}. Shipped 42 merged PRs, 4 releases, and {metrics.attached} public apps from {metrics.counted} selected GitHub sources.</p>
            <p className="profile-builder-note">{profile.note}</p>
            <StateStatusStrip productState={productState} publicArtifact={!ownerView} session={session} workflow={workflow} />
            {ownerView && (
              <div className="owner-hero-actions">
                <button className="secondary light" onClick={() => navigate("/repos")} type="button">Review sources</button>
                <button className="secondary light" onClick={() => navigate("/edit-profile")} type="button">Edit profile</button>
                <button className="secondary light" data-preview-action="enter" onClick={() => setPublicPreview(true)} type="button">View as public</button>
              </div>
            )}
            <div className="proof-chain"><span>Selected repos</span><span>Released apps</span><span>Merged PRs</span><span>Public receipts</span></div>
            <div className="action-row small">
              <button className="primary" onClick={() => navigate("/receipt")} type="button">Featured receipt</button>
              <button className="secondary light" data-share-action="proof" onClick={() => void share("proof")} type="button">Copy card link</button>
              {ownerView && <button className="secondary light" onClick={() => navigate("/edit-profile")} type="button">Edit profile</button>}
              {!session.isAuthenticated && <button className="secondary light" onClick={() => navigate("/signup")} type="button">Create your PRBar card</button>}
            </div>
          </div>
        </div>
        <aside className="profile-aside">
          <b>{profile.availability}</b>
          <StatPills items={[...builder.tools, ...builder.domains]} />
        </aside>
      </section>
      {ownerView ? (
        <section className="owner-proof-bar">
          <div>
            <span>Owner view</span>
            <h2>Card controls</h2>
            <p>You are signed in as the builder. Edit the identity, adjust selected sources, or preview what signed-out visitors see.</p>
          </div>
          <div className="owner-proof-actions">
            <button onClick={() => navigate("/edit-profile")} type="button"><b>Edit profile</b><em>Name, handle, title, and availability.</em></button>
            <button onClick={() => navigate("/repos")} type="button"><b>Sources & Privacy</b><em>{metrics.counted} selected sources power this proof.</em></button>
            <button data-preview-action="enter" onClick={() => setPublicPreview(true)} type="button"><b>View as public</b><em>Hide owner tools without losing your session.</em></button>
          </div>
        </section>
      ) : session.isAuthenticated ? (
        <section className="owner-proof-bar public-preview-bar"><h2>This is how signed-out visitors see the PRBar card.</h2><button className="primary" onClick={() => setPublicPreview(false)} type="button">Exit public preview</button></section>
      ) : null}
      <section className="proof-resume-layout proof-artifact">
        <div className="proof-resume-main">
          <ProofSummary metrics={proofMetrics} />
          <FeaturedReceipt navigate={navigate} />
          <AppProof navigate={navigate} />
          <ProofTimeline />
        </div>
        <ShareRail metrics={proofMetrics} profile={profile} share={share} shareFeedback={workflow.shareFeedback} shareOutput={workflow.shareOutput} />
      </section>
      {!session.isAuthenticated && (
        <section className="visitor-proof-cta">
          <div>
            <span>Potential user view</span>
            <h2>Want proof like this?</h2>
            <p>PRBar turns PRs, releases, app updates, and shipped features into a beautiful resume card you can share anywhere.</p>
          </div>
          <div className="action-row small">
            <button className="primary" onClick={() => navigate("/signup")} type="button">Create your PRBar card</button>
            <button className="secondary light" onClick={() => navigate("/signin")} type="button">Sign in</button>
            <button className="secondary light" type="button">Inspect {shortProfilePath(profile)}</button>
          </div>
        </section>
      )}
    </>
  );
}

function StateStatusStrip({
  publicArtifact = false,
  productState,
  session,
  workflow,
}: {
  publicArtifact?: boolean;
  productState: ProductState;
  session?: SessionState;
  workflow?: WorkflowState;
}) {
  if (publicArtifact) {
    return (
      <div className="state-strip" data-product-stage={productState.stage}>
        <div>
          <span>{productState.label}</span>
        </div>
        <p>Public preview. Owner controls and GitHub connection details are hidden from visitors.</p>
      </div>
    );
  }

  const metrics = workflow ? sourceMetrics(workflow, productState.stage === "public-prospect" ? "public" : "draft") : null;
  const details = [
    session ? (session.isAuthenticated ? "Signed in" : "Signed out") : null,
    session ? (session.githubConnected ? "GitHub connected" : "GitHub not connected") : null,
    workflow ? (workflow.published ? "Live PRBar card" : "Draft PRBar card") : null,
    metrics ? `${metrics.counted} sources selected` : null,
  ].filter(Boolean);

  return (
    <div className="state-strip" data-product-stage={productState.stage}>
      <div>
        <span>{productState.label}</span>
        <b>{productState.description}</b>
      </div>
      {details.length > 0 && <p>{details.join(" · ")}</p>}
    </div>
  );
}

function DraftOwnerProofPage({
  metrics,
  navigate,
  productState,
  profile,
  publishWorkflow,
  session,
  workflow,
}: NavigateProps & {
  metrics: ReturnType<typeof sourceMetrics>;
  publishWorkflow: () => void;
  productState: ProductState;
  profile: ProfileState;
  session: SessionState;
  workflow: WorkflowState;
}) {
  const connected = session.githubConnected;

  return (
    <>
      <section className="profile-hero draft-proof-hero">
        <div className="profile-main">
          <span className="avatar xl">{profile.initials}</span>
          <div>
            <p className="eyebrow">Card draft</p>
            <h1>{connected ? "Your PRBar card is almost shareable." : "Connect GitHub to build your card."}</h1>
            <p>
              {connected
                ? `${profile.name}'s card is claimed and GitHub proof is connected. Review the selected sources, publish the card, then copy the link anywhere.`
                : `${profile.name}'s card is claimed. Connect GitHub next so PRBar can import release tags, merged PRs, checks, and selected repo proof.`}
            </p>
            <StateStatusStrip productState={productState} session={session} workflow={workflow} />
            <div className="action-row small">
              <button className="primary" onClick={() => navigate(connected ? "/repos" : "/connect-github")} type="button">{connected ? "Review sources" : "Connect GitHub"}</button>
              {connected && <button className="secondary light" disabled={!workflow.sourcesReviewed} onClick={publishWorkflow} type="button">Publish PRBar card</button>}
              <button className="secondary light" onClick={() => navigate("/edit-profile")} type="button">Edit profile</button>
            </div>
          </div>
        </div>
        <aside className="profile-aside draft-proof-aside">
          <b>{connected ? "Draft status" : "Setup status"}</b>
          <p>
            {connected
              ? `${metrics.counted} selected sources, ${metrics.attached} attached apps, ${metrics.hidden} private names hidden.`
              : "No GitHub source proof is public yet. Connect selected repo access before choosing sources or publishing."}
          </p>
          <SetupStepper active={session.githubConnected ? "/repos" : "/connect-github"} />
        </aside>
      </section>
      <section className="draft-proof-dashboard">
        <article>
          <span>1</span>
          <h2>{connected ? "Builder card" : "First preview"}</h2>
          <p>{connected ? "The card is ready. It will open proof details after publish." : "Connect GitHub and PRBar will generate the first card preview from selected repos, releases, checks, and app updates."}</p>
          {connected ? <BuilderCard profile={profile} compact appsCount={metrics.attached} /> : <FirstProofPreview profile={profile} />}
        </article>
        <article>
          <span>2</span>
          <h2>{connected ? "Selected proof" : "Connect proof source"}</h2>
          <p>
            {connected
              ? `${metrics.counted} sources are counted, ${metrics.excluded} are excluded, and private names stay hidden until revealed.`
              : "Authorize selected GitHub access before PRBar can count PRs, releases, checks, or app proof."}
          </p>
          <button className="secondary light wide" onClick={() => navigate(connected ? "/repos" : "/connect-github")} type="button">{connected ? "Open Sources & Privacy" : "Connect GitHub"}</button>
        </article>
        <article>
          <span>3</span>
          <h2>{connected ? "Publish next" : "Publish later"}</h2>
          <p>{connected ? "Publishing turns the draft into a signed-out card view with receipts, app proof, and share actions." : "Publishing unlocks after GitHub is connected and source choices have been reviewed."}</p>
          {connected ? (
            <button className="primary wide" data-proof-action="publish-draft" disabled={!workflow.sourcesReviewed} onClick={publishWorkflow} type="button">Publish PRBar card</button>
          ) : (
            <button className="secondary light wide" onClick={() => navigate("/connect-github")} type="button">Connect GitHub first</button>
          )}
        </article>
      </section>
    </>
  );
}

function FirstProofPreview({ profile }: { profile: ProfileState }) {
  return (
    <div className="first-proof-preview" aria-label="First PRBar card preview">
      <div className="first-proof-preview-header">
        <span>{profile.handle}</span>
        <b>{profile.name}</b>
      </div>
      <p>PRBar will fill this preview after GitHub is connected.</p>
      <div className="first-proof-preview-grid">
        <span>PR velocity</span>
        <span>Release tags</span>
        <span>App proof</span>
        <span>Receipts</span>
      </div>
    </div>
  );
}

function ProofSummary({ metrics }: { metrics: ReturnType<typeof sourceMetrics> }) {
  return (
    <article className="resume-summary-panel">
      <div>
        <span>What this proves</span>
        <h2>42 PRs, 4 releases, {metrics.attached} apps shipped.</h2>
        <p>42 merged PRs, 4 releases, and {metrics.attached} public apps moved from prototype to shipped.</p>
      </div>
      <div className="resume-stat-grid">
        <b><strong>42</strong><span>Merged PRs</span></b>
        <b><strong>4</strong><span>Releases</span></b>
        <b><strong>{metrics.attached}</strong><span>Shipped apps</span></b>
      </div>
    </article>
  );
}

function ProofLinks() {
  return (
    <div className="proof-links" aria-label="Source proof links">
      <button type="button">GitHub release</button>
      <button type="button">{release.repo}</button>
      <button type="button">{release.tag}</button>
    </div>
  );
}

function FeaturedReceipt({ navigate }: NavigateProps) {
  const prLabels = ["Discovery filters merged", "Release notes imported", "Scoring tests added"];

  return (
    <article className="resume-receipt-panel" id="latest-receipt" tabIndex={-1}>
      <div className="resume-section-heading">
        <span>Current shipped thing</span>
        <h2>{release.title}</h2>
        <p>{release.summary}</p>
      </div>
      <div className="receipt-proof-layout">
        <div className="receipt-proof-stack">
          <StatPills items={release.facts} />
          <ProofLinks />
          <p className="trust-note">GitHub facts are imported from releases, PRs, tags, checks, and timestamps. Builder annotations add context, but cannot rewrite them.</p>
        </div>
        <div className="pr-list">
          {release.prList.map((pr, index) => <div key={pr}><b>{pr}</b><span>{prLabels[index]}</span><em>Merged · CI passed</em></div>)}
        </div>
      </div>
      <blockquote>This release moved the project from useful prototype to something people can revisit weekly.</blockquote>
      <div className="action-row small">
        <button className="secondary light" onClick={() => navigate("/receipt")} type="button">Open receipt section</button>
        <button className="secondary light" onClick={() => navigate("/project")} type="button">Open app proof section</button>
      </div>
    </article>
  );
}

function AppPreview({ app }: { app: (typeof apps)[number] }) {
  return (
    <div className="app-preview" aria-label={`${app.name} app preview`}>
      <span>{app.status}</span>
      <strong>{app.name}</strong>
      <i />
      <i />
      <i />
    </div>
  );
}

function AppProof({ navigate }: NavigateProps) {
  return (
    <article className="app-proof-panel" id="app-proof" tabIndex={-1}>
      <div className="resume-section-heading">
        <span>App proof</span>
        <h2>Proof attaches to the things Maya shipped.</h2>
      </div>
      <div className="app-proof-strip">
        {apps.map((app) => (
          <article key={app.name}>
            <AppPreview app={app} />
            <div>
              <span>{app.status}</span>
              <h3>{app.name}</h3>
              <p>{app.tagline}</p>
              <StatPills items={app.proof} />
            </div>
          </article>
        ))}
      </div>
      <div className="action-row small">
        <button className="secondary light" onClick={() => navigate("/project")} type="button">Open app proof section</button>
        <button className="secondary light" onClick={() => navigate("/receipt")} type="button">Open receipt section</button>
      </div>
    </article>
  );
}

function ProofTimeline() {
  return (
    <article className="resume-timeline-panel">
      <div className="resume-section-heading"><span>Proof timeline</span><h2>Recent shipped work, in order.</h2></div>
      <div className="resume-timeline">
        {timeline.map(([date, title, detail]) => <article key={title}><span>{date}</span><div><h3>{title}</h3><p>{detail}</p></div></article>)}
      </div>
    </article>
  );
}

function ShareRail({
  metrics,
  profile,
  share,
  shareFeedback,
  shareOutput,
}: {
  metrics: ReturnType<typeof sourceMetrics>;
  profile: ProfileState;
  share: (action: ShareAction) => void;
  shareFeedback: string;
  shareOutput: string;
}) {
  return (
    <aside className="proof-share-rail" id="builder-card" tabIndex={-1}>
      <div className="rail-sticky">
        <div className="panel-heading"><span>Short version</span><h2>Builder card</h2></div>
        <p>The card is the portable version of this page. It previews the proof, then opens the deeper receipt and source context when someone wants to inspect it.</p>
        <BuilderCard profile={profile} compact appsCount={metrics.attached} />
        <div className="share-output-grid">
          <button data-share-action="card" onClick={() => share("card")} type="button"><span>PRBar card</span><b>Copy card link</b></button>
          <button data-share-action="proof" onClick={() => share("proof")} type="button"><span>Proof details</span><b>Copy full card link</b></button>
          <button data-share-action="image" onClick={() => share("image")} type="button"><span>Card image</span><b>Download card image</b></button>
          <button data-share-action="embed" onClick={() => share("embed")} type="button"><span>Embed</span><b>Copy card embed</b></button>
        </div>
        <p className="share-feedback" data-share-feedback>{shareFeedback || "Share links are ready."}</p>
        <div className="share-output-preview" aria-label="Latest share output">
          <span>Latest output</span>
          <code data-share-output>{shareOutput || fullProfileLink(profile)}</code>
        </div>
        <div className="rail-source-note">
          <b>Source controlled</b>
          <span>{metrics.counted} selected sources power the card, receipt, app proof, and timeline. Deep links keep each proof section shareable inside one artifact.</span>
        </div>
      </div>
    </aside>
  );
}

function AccountPage({ navigate, profile, resetSession, session }: NavigateProps & {
  profile: ProfileState;
  resetSession: () => void;
  session: SessionState;
}) {
  const logout = () => {
    resetSession();
    navigate("/home");
  };
  const gitHubActionLabel = session.githubConnected ? "Manage GitHub sources" : "Connect GitHub";
  const gitHubActionPath = session.githubConnected ? "/repos" : "/connect-github";

  return (
    <section className="account-layout owner-dashboard-layout">
      <aside className="account-rail">
        <h2>Account</h2>
        <p>Permissions and data controls for {profile.name}.</p>
        <p className="account-version">PRBar v{appVersionDisplayValue()}</p>
        <button className="primary wide" onClick={() => navigate(gitHubActionPath)} type="button">{gitHubActionLabel}</button>
      </aside>
      <div className="account-main">
        <div className="control-section-heading">
          <span>Account & permissions</span>
          <h1>Control access, exports, and privacy defaults.</h1>
        </div>
        <div className="permission-cards">
          <article><b>Session</b><span>{session.isAuthenticated ? "Signed in as maya@example.com" : "Signed out preview"}</span><em>Active</em></article>
          <article><b>GitHub</b><span>{session.githubConnected ? "Connected with selected repo access" : "Not connected yet"}</span><em>Manage</em></article>
          <article><b>Private sources</b><span>Names hidden by default</span><em>Protected</em></article>
          <article><b>Exports</b><span>Card image, embed, and full card link enabled</span><em>Active</em></article>
          <article><b>Local storage</b><span>Session, profile, selected sources, publish state, and share state persist in this browser</span><em>Client-only</em></article>
          <article><b>Version</b><span>PRBar v{appVersionDisplayValue()}</span><em>Release</em></article>
        </div>
        <div className="action-row small">
          <button className="primary" onClick={() => navigate(gitHubActionPath)} type="button">{gitHubActionLabel}</button>
          <button className="secondary light" data-auth-action="logout" onClick={logout} type="button">Log out</button>
        </div>
      </div>
    </section>
  );
}

function SetupStepper({ active }: { active: string }) {
  const steps = [
    ["/connect-github", "Connect GitHub"],
    ["/repos", "Customize"],
    ["/profile", "Publish & share"],
  ];

  return (
    <ol className="setup-stepper" aria-label="PRBar card setup steps">
      {steps.map(([path, label], index) => <li className={path === active ? "active" : ""} key={path}><span>{String(index + 1).padStart(2, "0")}</span><b>{label}</b></li>)}
    </ol>
  );
}

function WorkflowPath({ navigate, session, workflow }: NavigateProps & { session: SessionState; workflow: WorkflowState }) {
  return (
    <section className="workflow-path-panel compact" aria-label="Current PRBar card path">
      <span>Path to shareable card</span>
      <div className="workflow-path-grid">
        {setupStepStates(session, workflow).map((step, index) => (
          <button className={step.done ? "done" : "pending"} key={step.label} onClick={() => navigate(step.path)} type="button">
            <small>{String(index + 1).padStart(2, "0")}</small>
            <b>{step.label}</b>
          </button>
        ))}
      </div>
    </section>
  );
}

function SetupChecklist({ session, workflow }: { session: SessionState; workflow: WorkflowState }) {
  const metrics = sourceMetrics(workflow);
  const items = [
    { done: session.githubConnected, label: "GitHub connected", note: session.githubConnected ? "Release tags, merged PRs, and checks are available." : "Connect selected repos before proof can be published." },
    { done: session.githubConnected && workflow.sourcesReviewed, label: "Sources customized", note: workflow.sourcesReviewed ? `${metrics.counted} selected sources confirmed for the card.` : "Confirm which GitHub sources count before publishing." },
    { done: workflow.published, label: "PRBar card published", note: workflow.published ? "The public card is live and ready to share." : "Publish after sources and profile copy look right." },
  ];
  const complete = items.filter((item) => item.done).length === items.length;

  return (
    <section className="setup-checklist-panel" aria-label="PRBar card setup checklist">
      <div className="setup-checklist-heading">
        <span>{complete ? "SETUP COMPLETE" : "FINISH SETUP"}</span>
        <b>{items.filter((item) => item.done).length}/{items.length} complete</b>
      </div>
      <ol className="setup-checklist">
        {items.map((item) => <li className={item.done ? "done" : "pending"} key={item.label}><span>{item.done ? "Done" : "Next"}</span><b>{item.label}</b><em>{item.note}</em></li>)}
      </ol>
    </section>
  );
}

function BuilderCard({ appsCount = builder.stats.apps, compact = false, profile }: { appsCount?: number; compact?: boolean; profile: ProfileState }) {
  return (
    <article className={`builder-link-card ${compact ? "compact" : ""}`}>
      <div className="builder-link-identity">
        <div>
          <span>{profile.handle}</span>
          <h3>{profile.name}</h3>
        </div>
        <div className="avatar">{profile.initials}</div>
      </div>
      <p>{profile.title}. Proof from selected GitHub repos, releases, and app updates.</p>
      <div className="builder-link-chart" aria-label="Selected GitHub proof summary">
        {[34, 58, 42, 76, 64, 100, 82].map((value) => <i key={value} style={{ height: `${value}%` }} />)}
      </div>
      <div className="builder-link-stats">
        <div><b>42</b><span>merged PRs</span></div>
        <div><b>6</b><span>active repos</span></div>
        <div><b>{appsCount}</b><span>shipped apps</span></div>
      </div>
    </article>
  );
}

function StatPills({ items }: { items: string[] }) {
  return <div className="stat-pills">{items.map((item) => <span key={item}>{item}</span>)}</div>;
}
