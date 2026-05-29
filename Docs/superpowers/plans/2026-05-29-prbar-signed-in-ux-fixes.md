# PRBar Signed-In UX Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Next.js PRBar prototype’s signed-in experience truthful, owner-first, and easy to understand across Dashboard, Builder Proof, Sources & Privacy, Account, and public/deep-link views.

**Architecture:** Keep the prototype client-side only and concentrated in `apps/web/app/prototype-app.tsx`, but tighten the state model so public proof, draft source edits, source review, and signed-in navigation are explicit. Use `apps/web/smoke-test.js` as the primary regression harness, with CSS changes in `apps/web/app/globals.css` for mobile navigation, operational page scale, and the 3D Builder Card.

**Tech Stack:** Next.js App Router, React 19, TypeScript, CSS, localStorage-backed mock state, Playwright smoke tests.

---

## File Structure

- Modify: `apps/web/app/prototype-app.tsx`
  - Add explicit workflow state for source review, draft changes, and published source snapshots.
  - Gate unpublished Builder Proof deep-link aliases.
  - Make signed-in navigation and home/dashboard hierarchy owner-first.
  - Clarify copy around Builder Card, Builder Proof, GitHub proof, public preview, source privacy, and share actions.
- Modify: `apps/web/app/globals.css`
  - Compact signed-in mobile topbar.
  - Add visual treatment for Dashboard nav, draft-update banners, source segmented controls, operational headings, and responsive Builder Card sizing.
- Modify: `apps/web/smoke-test.js`
  - Add regression coverage for unpublished alias gates, signed-in Dashboard IA, explicit source review, publish snapshot behavior, public preview privacy, and mobile topbar height.
- Optional modify: `apps/web/scripts/parity-qa.js`
  - Only update if its route/copy expectations conflict with the new signed-in IA.

## Product Invariants

- No feed, threads, or social network affordances.
- The solo-user path remains: claim card -> connect GitHub -> review sources -> publish Builder Proof -> share anywhere.
- Builder Card is the short portable entry point; Builder Proof is the full inspectable artifact.
- Public visitors never see owner session state, GitHub connection status, or unpublished draft changes.
- Owner source edits after publishing never silently unpublish the live proof.

---

### Task 1: Make Builder Proof Routes State-Truthful

**Files:**
- Modify: `apps/web/app/prototype-app.tsx`
- Modify: `apps/web/smoke-test.js`

- [ ] **Step 1: Add proof route helpers**

In `apps/web/app/prototype-app.tsx`, near the current `ProofRoute` type and route constants, add helpers so `/profile`, `/card`, `/receipt`, and `/project` share the same public gate:

```tsx
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
```

Remove the older `type ProofRoute = "/profile" | "/card" | "/receipt" | "/project";` declaration so there is one source of truth.

- [ ] **Step 2: Route all proof pages through the helper**

Replace the proof route render condition in `PrototypeApp`:

```tsx
{["/profile", "/card", "/receipt", "/project"].includes(route) && (
```

with:

```tsx
{isProofRoute(route) && (
```

and pass `route={route}` without casting.

- [ ] **Step 3: Gate unpublished alias routes for signed-out visitors**

In `ProfilePage`, replace the current unpublished gate:

```tsx
if (!workflow.published && !aliasRoute) {
```

with:

```tsx
if (!workflow.published) {
```

Keep the signed-in branch rendering `DraftOwnerProofPage`. Keep the signed-out empty state, but update the copy to avoid "proof resume":

```tsx
<p>{profile.name.split(/\s+/)[0]} has not made this Builder Proof public. The owner can connect GitHub, review sources, publish Builder Proof, then share the public link anywhere.</p>
```

- [ ] **Step 4: Use the alias helper for scrolling**

Replace the local alias target map in `ProfilePage` with:

```tsx
const targetId = proofAliasTarget(route);
if (!targetId) return;
```

Expected behavior:
- Signed-in unpublished `/card`, `/receipt`, and `/project` show the owner draft experience.
- Signed-out unpublished `/card`, `/receipt`, and `/project` show the same unpublished public gate as `/profile`.
- Published aliases still scroll to the right section.

- [ ] **Step 5: Add smoke assertions for the route leak**

In `apps/web/smoke-test.js`, after the first signed-out route loop clears localStorage, add explicit checks:

```js
for (const route of ["#/card", "#/receipt", "#/project"]) {
  await page.goto(`${baseUrl}/${route}`, { waitUntil: "networkidle" });
  await assertBodyIncludes(page, `${route} unpublished gate`, "Builder Proof is not published yet.");
  await assertBodyExcludes(page, `${route} unpublished should not leak receipt`, "SideProject Radar v2.1");
  await assertBodyExcludes(page, `${route} unpublished should not leak share rail`, "Share links are ready.");
}
```

- [ ] **Step 6: Verify**

Run:

```bash
cd /Users/neonwatty/Desktop/prbar/apps/web
npm run lint
npm run build
npm run smoke
```

Expected:
- `npm run lint` exits 0.
- `npm run build` exits 0.
- `npm run smoke` exits 0.

---

### Task 2: Make Signed-In IA Dashboard-First

**Files:**
- Modify: `apps/web/app/prototype-app.tsx`
- Modify: `apps/web/app/globals.css`
- Modify: `apps/web/smoke-test.js`

- [ ] **Step 1: Split signed-out and signed-in nav**

Replace the current `primaryRoutes` constant with signed-out base routes:

```tsx
const signedOutRoutes = [
  { label: "Home", path: "/home" },
  { label: "Builder Proof", path: "/profile" },
  { label: "Sources & Privacy", path: "/repos" },
];

const signedInRoutes = [
  { label: "Dashboard", path: "/user" },
  { label: "Builder Proof", path: "/profile" },
  { label: "Sources & Privacy", path: "/repos" },
  { label: "Account", path: "/account" },
];
```

Update `validRoutes` to include both arrays:

```tsx
const validRoutes = new Set([
  ...signedOutRoutes.map((route) => route.path),
  ...signedInRoutes.map((route) => route.path),
  "/signup",
  "/signin",
  "/login",
  "/logout",
  "/onboarding",
  "/connect-github",
  "/edit-profile",
  ...proofRoutes,
]);
```

- [ ] **Step 2: Update section grouping**

Replace `sectionFor` with:

```tsx
function sectionFor(path: string, session?: SessionState) {
  if (path === "/user" || path === "/edit-profile") return session?.isAuthenticated ? "/user" : "/profile";
  if (["/card", "/receipt", "/project"].includes(path)) return "/profile";
  if (path === "/connect-github") return session?.isAuthenticated ? "/repos" : "/home";
  if (signedInRoutes.some((route) => route.path === path)) return path;
  if (signedOutRoutes.some((route) => route.path === path)) return path;
  return "/home";
}
```

Update `Shell`:

```tsx
const activeSection = sectionFor(route, session);
const navRoutes = session.isAuthenticated ? signedInRoutes : signedOutRoutes;
```

- [ ] **Step 3: Put signed-in home workspace before the marketing hero**

In `HomePage`, move the `session.isAuthenticated && <SignedInHomePanel ... />` block above the `<section className="hero">` block.

Add a signed-in CSS hook:

```tsx
<section className={`hero ${session.isAuthenticated ? "hero-secondary" : ""}`}>
```

In `apps/web/app/globals.css`, add:

```css
.hero-secondary {
  padding-top: 28px;
}

.hero-secondary h1 {
  font-size: clamp(2.4rem, 5vw, 5rem);
}
```

- [ ] **Step 4: Rename owner dashboard copy**

In `UserProfilePage`, change:

```tsx
<span>User profile</span>
<h1>Manage the identity behind Builder Proof.</h1>
```

to:

```tsx
<span>Dashboard</span>
<h1>Manage your Builder Proof workspace.</h1>
```

Change `Open profile dashboard` buttons to `Open Dashboard`.

- [ ] **Step 5: Persist the claimed handle during signup**

Update `AuthPage` props to receive `saveProfile` and `profile`:

```tsx
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
```

Add state and inputs:

```tsx
const [handle, setHandle] = useState(profile.handle);
const [name, setName] = useState(profile.name);
```

In `submit`, before `updateSession`, add:

```tsx
if (signup) {
  const cleanHandle = handle.trim().startsWith("@") ? handle.trim() : `@${handle.trim() || "maya.codes"}`;
  saveProfile({
    ...profile,
    handle: cleanHandle,
    link: linkFromHandle(cleanHandle),
    name: name.trim() || profile.name,
  });
}
```

Update the two `AuthPage` call sites in `PrototypeApp` to pass `profile={profile}` and `saveProfile={saveProfile}`.

- [ ] **Step 6: Add smoke assertions**

In `apps/web/smoke-test.js`, after login:

```js
await assertLocatorIncludes(page, ".topbar .nav", "/user signed-in nav", "Dashboard");
await assertLocatorIncludes(page, ".topbar .nav", "/user signed-in nav", "Account");
await assertBodyIncludes(page, "/user dashboard heading", "Manage your Builder Proof workspace.");
```

For signed-in `/home`:

```js
await assertSectionNearTop(page, "/home signed-in workspace", ".signed-in-home-panel");
```

If `.signed-in-home-panel` is not already on the section, add it to the `SignedInHomePanel` root:

```tsx
<section className="signed-in-home-panel owner-home-panel">
```

- [ ] **Step 7: Verify**

Run:

```bash
cd /Users/neonwatty/Desktop/prbar/apps/web
npm run lint
npm run build
npm run smoke
```

Expected all pass.

---

### Task 3: Add Explicit Source Review And Non-Silent Publish Updates

**Files:**
- Modify: `apps/web/app/prototype-app.tsx`
- Modify: `apps/web/app/globals.css`
- Modify: `apps/web/smoke-test.js`

- [ ] **Step 1: Extend `WorkflowState`**

Change `WorkflowState` to:

```tsx
type WorkflowState = {
  published: boolean;
  sourcesReviewed: boolean;
  draftDirty: boolean;
  shareFeedback: string;
  shareOutput: string;
  sources: Record<string, SourceState>;
  publicSources: Record<string, SourceState> | null;
};
```

- [ ] **Step 2: Update defaults and normalization**

In `defaultWorkflow`, add:

```tsx
sourcesReviewed: false,
draftDirty: false,
publicSources: null,
```

In `normalizeWorkflow`, preserve booleans safely:

```tsx
sourcesReviewed: Boolean(value?.sourcesReviewed),
draftDirty: Boolean(value?.draftDirty),
```

Create a local helper above `normalizeWorkflow`:

```tsx
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
    })
  );
}
```

Use it for both `sources` and `publicSources`:

```tsx
const normalizedSources = normalizeSourceRecord(value?.sources, defaults.sources);
const normalizedPublicSources = value?.publicSources ? normalizeSourceRecord(value.publicSources, defaults.sources) : null;
```

- [ ] **Step 3: Split metrics by source record**

Replace `sourceMetrics(workflow: WorkflowState)` with:

```tsx
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
  };
}

function sourceMetrics(workflow: WorkflowState, scope: "draft" | "public" = "draft") {
  return sourceMetricsFromRecord(scope === "public" && workflow.publicSources ? workflow.publicSources : workflow.sources);
}
```

- [ ] **Step 4: Add publish helper**

Near `updateWorkflow`, add:

```tsx
const publishWorkflow = useCallback(() => {
  updateWorkflow((current) => ({
    ...current,
    published: true,
    sourcesReviewed: true,
    draftDirty: false,
    publicSources: structuredClone(current.sources),
    shareFeedback: current.published ? "Published updates to the public Builder Proof." : "",
    shareOutput: current.shareOutput,
  }));
}, [updateWorkflow]);
```

Pass `publishWorkflow` to `ReposPage`, `ProfilePage`, and `DraftOwnerProofPage` instead of duplicating `updateWorkflow((current) => ({ ...current, published: true }))`.

- [ ] **Step 5: Change source edits to draft updates**

In `ReposPage.setSource`, replace:

```tsx
current.published = false;
current.shareFeedback = "";
current.shareOutput = "";
```

with:

```tsx
current.sourcesReviewed = false;
current.draftDirty = current.published;
current.shareFeedback = current.published
  ? "Source changes saved to draft. Publish updates to refresh the public Builder Proof."
  : "Source choices saved to draft. Review and publish when ready.";
current.shareOutput = "";
```

- [ ] **Step 6: Add a source review confirmation**

In `ReposPage`, add a button in `publish-status-card` before publish:

```tsx
<button
  className="secondary light wide"
  data-source-action="confirm-review"
  onClick={() => updateWorkflow((current) => ({ ...current, sourcesReviewed: true, shareFeedback: "Source choices reviewed. Builder Proof is ready to publish." }))}
  type="button"
>
  Confirm source choices
</button>
```

Make the publish/update CTA disabled until reviewed:

```tsx
<button
  className="primary wide"
  data-proof-action={workflow.published ? "publish-updates" : "publish"}
  disabled={!workflow.sourcesReviewed}
  onClick={publishWorkflow}
  type="button"
>
  {workflow.published && workflow.draftDirty ? "Publish updates" : "Publish Builder Proof"}
</button>
```

Add explanatory text:

```tsx
{!workflow.sourcesReviewed && <p className="draft-warning">Review and confirm source choices before publishing.</p>}
{workflow.draftDirty && <p className="draft-warning">Your live Builder Proof is still public. These source changes are private until you publish updates.</p>}
```

- [ ] **Step 7: Update setup step logic**

In `setupStepStates`, change:

```tsx
{ done: session.githubConnected && metrics.counted > 0, label: "Choose what counts", path: "/repos" },
```

to:

```tsx
{ done: session.githubConnected && workflow.sourcesReviewed, label: "Review sources", path: "/repos" },
```

In `SetupChecklist`, change the "Sources chosen" item to:

```tsx
{ done: session.githubConnected && workflow.sourcesReviewed, label: "Sources reviewed", note: workflow.sourcesReviewed ? `${metrics.counted} selected sources confirmed for Builder Proof.` : "Confirm which GitHub sources count before publishing." },
```

- [ ] **Step 8: Use public source snapshots for public views**

In `ProfilePage`, compute:

```tsx
const proofMetrics = useMemo(() => {
  const scope = ownerView ? "draft" : "public";
  return sourceMetrics(workflow, scope);
}, [ownerView, workflow]);
```

Use `proofMetrics` for public artifact sections and share rail. Keep owner bars free to mention draft metrics.

Acceptance:
- Public visitors see the last published source snapshot.
- Signed-in owners see draft changes and a "Publish updates" state.
- Editing sources after publish does not make the public proof disappear.

- [ ] **Step 9: Update CSS for disabled/draft warnings**

Add to `apps/web/app/globals.css`:

```css
.draft-warning {
  margin: 10px 0 0;
  color: #7c2d12;
  font-size: 0.9rem;
  line-height: 1.4;
}

button:disabled {
  cursor: not-allowed;
  opacity: 0.55;
}
```

- [ ] **Step 10: Add smoke assertions**

After GitHub connect in `apps/web/smoke-test.js`:

```js
await assertBodyIncludes(page, "/repos requires review", "Review and confirm source choices before publishing.");
const publishDisabled = await page.locator('[data-proof-action="publish"]').isDisabled();
if (!publishDisabled) throw new Error("/repos publish should be disabled before source review");
await page.locator('[data-source-action="confirm-review"]').click();
await page.locator('[data-proof-action="publish"]').click();
```

After editing a source post-publish:

```js
await page.goto(`${baseUrl}/#/repos`, { waitUntil: "networkidle" });
await page.locator('[data-source-id="maya/experiments"][data-source-action="exclude"]').click();
await assertBodyIncludes(page, "/repos draft update warning", "Source changes saved to draft.");
await assertBodyIncludes(page, "/repos publish updates", "Publish updates");
```

- [ ] **Step 11: Verify**

Run:

```bash
cd /Users/neonwatty/Desktop/prbar/apps/web
npm run lint
npm run build
npm run smoke
```

Expected all pass.

---

### Task 4: Simplify Source Controls And Public/Owner Copy

**Files:**
- Modify: `apps/web/app/prototype-app.tsx`
- Modify: `apps/web/app/globals.css`
- Modify: `apps/web/smoke-test.js`

- [ ] **Step 1: Rename privacy labels**

In `ReposPage`, replace row status:

```tsx
<b>{state.hidden || state.mode === "redacted" ? "hidden" : state.mode}</b>
```

with:

```tsx
<b>{state.mode === "excluded" ? "Excluded" : state.hidden || state.mode === "redacted" ? "Hidden from public" : "Public name visible"}</b>
```

Replace the privacy button label:

```tsx
{state.hidden ? "Hidden" : "Revealed"}
```

with:

```tsx
{state.hidden ? "Hidden from public" : "Reveal publicly"}
```

Replace the impact copy for hidden rows:

```tsx
"Counts selected proof while hiding private names on the public Builder Proof."
```

with:

```tsx
"Visible to you here. Hidden from public Builder Proof while still counting selected proof."
```

- [ ] **Step 2: Group count controls visually**

Wrap include/redact/exclude buttons in a segmented container:

```tsx
<div className="source-mode-segment" aria-label={`${source.name} count mode`}>
  <button ...>Include</button>
  <button ...>Redact</button>
  <button ...>Exclude</button>
</div>
<div className="source-secondary-actions">
  <button ...>{state.attached ? "App attached" : "Attach app"}</button>
  <button ...>{state.hidden ? "Hidden from public" : "Reveal publicly"}</button>
</div>
```

Keep existing `data-source-action` and `data-source-id` attributes so smoke tests continue to drive the controls.

- [ ] **Step 3: Add GitHub proof definition**

In `ConnectGithubPage`, under the permissions list, add:

```tsx
<p className="trust-note">GitHub proof means imported PR, release, tag, timestamp, and check metadata. Builder notes and app descriptions add context, but cannot change imported facts.</p>
```

In `FeaturedReceipt`, keep the existing trust note but change "Facts are locked from GitHub" to:

```tsx
GitHub facts are imported from releases, PRs, tags, checks, and timestamps. Builder annotations add context, but cannot rewrite them.
```

- [ ] **Step 4: Clean up share labels**

In `ShareRail`, change the button labels to:

```tsx
<button data-share-action="card" ...><span>Builder Card</span><b>Copy Builder Card link</b></button>
<button data-share-action="proof" ...><span>Builder Proof</span><b>Copy public Builder Proof link</b></button>
<button data-share-action="image" ...><span>Card image</span><b>Download Builder Card image</b></button>
<button data-share-action="embed" ...><span>Embed</span><b>Copy Builder Proof embed</b></button>
```

In share feedback, change:

```tsx
feedback: `Copied builder card link: ${fullProfileLink(profile)}#builder-card`,
```

to:

```tsx
feedback: `Copied Builder Card link: ${fullProfileLink(profile)}#builder-card`,
```

- [ ] **Step 5: Fix deep-link button labels**

In `FeaturedReceipt`, replace:

```tsx
Copy receipt deep link
View app proof deep link
```

with:

```tsx
Open receipt section
Open app proof section
```

In `AppProof`, replace:

```tsx
Open app proof deep link
Open receipt deep link
```

with:

```tsx
Open app proof section
Open receipt section
```

- [ ] **Step 6: Hide owner/session state in public preview strip**

Update `StateStatusStrip` to accept a `publicArtifact?: boolean` prop:

```tsx
function StateStatusStrip({ productState, publicArtifact = false, session, workflow }: { ...; publicArtifact?: boolean }) {
```

Before `details`, add:

```tsx
if (publicArtifact) {
  return (
    <div className="state-strip" data-product-stage={productState.stage}>
      <div>
        <span>{productState.label}</span>
        <b>Public preview. Owner controls and GitHub connection details are hidden from visitors.</b>
      </div>
    </div>
  );
}
```

Call it from published public preview/signed-out artifact areas with `publicArtifact={!ownerView}`.

- [ ] **Step 7: Add CSS for segmented controls**

Add:

```css
.source-mode-segment,
.source-secondary-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.source-mode-segment {
  padding: 4px;
  border: 1px solid rgba(15, 23, 42, 0.12);
  border-radius: 8px;
  background: rgba(248, 250, 252, 0.8);
}
```

- [ ] **Step 8: Update smoke assertions**

Replace assertions expecting old copy:

```js
await assertBodyIncludes(page, "/repos live hidden count", "3 private hidden");
```

with:

```js
await assertBodyIncludes(page, "/repos hidden public label", "Hidden from public");
await assertBodyIncludes(page, "/repos hidden explanation", "Visible to you here. Hidden from public Builder Proof");
```

Add:

```js
await assertBodyIncludes(page, "/connect github proof definition", "GitHub proof means imported PR, release, tag, timestamp, and check metadata.");
await assertBodyIncludes(page, "/profile share label", "Copy public Builder Proof link");
```

- [ ] **Step 9: Verify**

Run:

```bash
cd /Users/neonwatty/Desktop/prbar/apps/web
npm run lint
npm run build
npm run smoke
```

Expected all pass.

---

### Task 5: Polish Mobile Navigation, Operational Scale, And 3D Builder Card

**Files:**
- Modify: `apps/web/app/prototype-app.tsx`
- Modify: `apps/web/app/globals.css`
- Modify: `apps/web/smoke-test.js`

- [ ] **Step 1: Convert workflow map toggle copy on mobile**

In `Shell`, change the `.toc-toggle` button label from a generic workflow map action to:

```tsx
{workflowMapOpen ? "Close setup map" : "Setup map"}
```

Do not use this button as the primary mobile nav. The nav remains visible, but compact.

- [ ] **Step 2: Compact mobile topbar CSS**

Inside the existing mobile media query in `apps/web/app/globals.css`, add or adjust:

```css
@media (max-width: 760px) {
  .topbar {
    grid-template-columns: 1fr;
    gap: 10px;
    padding: 10px 12px;
  }

  .brand {
    min-height: 42px;
  }

  .nav,
  .topbar-account {
    width: 100%;
    gap: 6px;
  }

  .nav button,
  .topbar-account button {
    min-height: 36px;
    padding: 8px 10px;
    font-size: 0.82rem;
  }

  .topbar-profile span {
    display: none;
  }
}
```

Acceptance: at `390x844`, the topbar height should be under `132px`.

- [ ] **Step 3: Reduce operational page heading scale**

Add:

```css
.account-layout .control-section-heading h1,
.control-room .control-section-heading h2,
.profile-edit-form .control-section-heading h1 {
  font-size: clamp(2rem, 4vw, 3.4rem);
  line-height: 1.02;
}
```

- [ ] **Step 4: Make the 3D Builder Card responsive**

In CSS, update the card wrapper:

```css
.builder-link-card-wrap {
  aspect-ratio: 4 / 3;
  min-height: 0;
  height: auto;
  max-height: min(620px, calc(100vh - 190px));
  scroll-margin-top: 150px;
}
```

Inside mobile media:

```css
.builder-link-card-wrap {
  aspect-ratio: 3 / 4;
  max-height: 520px;
  scroll-margin-top: 150px;
}

.builder-link-face {
  padding: 22px;
}
```

- [ ] **Step 5: Move owner actions higher on Builder Proof**

In `ProfilePage`, for `ownerView`, add a compact action row inside the hero after `StateStatusStrip`:

```tsx
{ownerView && (
  <div className="owner-hero-actions">
    <button className="secondary light" onClick={() => navigate("/repos")} type="button">Review sources</button>
    <button className="secondary light" onClick={() => navigate("/edit-profile")} type="button">Edit profile</button>
    <button className="secondary light" data-preview-action="enter" onClick={() => setPublicPreview(true)} type="button">View as public</button>
  </div>
)}
```

Keep the larger `owner-proof-bar` below for detailed controls.

- [ ] **Step 6: Add CSS for owner hero actions**

```css
.owner-hero-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 14px;
}
```

- [ ] **Step 7: Add Playwright checks to smoke test**

In `apps/web/smoke-test.js`, add helper:

```js
async function assertTopbarCompact(page, route) {
  const height = await page.locator(".topbar").evaluate((element) => element.getBoundingClientRect().height);
  if (height > 132) {
    throw new Error(`${route} mobile topbar too tall: ${height}px`);
  }
}
```

Call it after signed-in mobile `/home`, `/user`, `/profile`, and `/repos` page loads.

Add a 3D card visibility check:

```js
await page.goto(`${baseUrl}/#/home`, { waitUntil: "networkidle" });
const cardBox = await page.locator("[data-builder-link-card]").boundingBox();
if (!cardBox || cardBox.height < 360 || cardBox.height > 620) {
  throw new Error(`#/home Builder Card has unexpected mobile height: ${cardBox?.height}`);
}
```

- [ ] **Step 8: Verify visually and with tests**

Run:

```bash
cd /Users/neonwatty/Desktop/prbar/apps/web
npm run lint
npm run build
npm run smoke
```

Then, with the dev server running, capture:

```bash
cd /Users/neonwatty/Desktop/prbar/apps/web
npm run dev -- -p 4185 -H 127.0.0.1
```

Use Playwright or the Codex browser to inspect:
- `http://127.0.0.1:4185/#/home` signed in, mobile and desktop.
- `http://127.0.0.1:4185/#/user` signed in, mobile and desktop.
- `http://127.0.0.1:4185/#/profile` signed in/public preview, mobile and desktop.
- `http://127.0.0.1:4185/#/repos` signed in after GitHub connect, mobile and desktop.

Expected:
- No horizontal overflow.
- Mobile topbar leaves most of the viewport for content.
- Signed-in home shows owner workspace before marketing.
- Builder Card is visible, flippable, and not clipped.

---

### Task 6: Final Regression Sweep And Acceptance Receipt

**Files:**
- Modify: `apps/web/smoke-test.js`
- Optional create: `docs/goals/prbar-nextjs-client-prototype/notes/signed-in-ux-fixes-qa.md`

- [ ] **Step 1: Run full local verification**

Run:

```bash
cd /Users/neonwatty/Desktop/prbar/apps/web
npm run lint
npm run build
npm run smoke
npm run qa
```

Expected:
- All commands exit 0.
- If `npm run qa` has expected copy drift from the old mockup, update only the stale expectations and rerun it.

- [ ] **Step 2: Drive the core workflows manually**

Using Playwright CLI or Codex browser, verify these workflows:

1. Signed-out prospect:
   - `/home` explains PRBar as the new resume for AI-native builders.
   - `/profile` unpublished shows a gate.
   - `/card`, `/receipt`, `/project` unpublished also show a gate.
2. New owner:
   - `/signup` claims handle.
   - `/connect-github` defines GitHub proof.
   - `/repos` requires source review before publish.
   - `/profile` draft has no public-share confusion.
3. Published owner:
   - `/user` is Dashboard and shows next action.
   - `/profile` shows owner hero actions.
   - public preview hides session/GitHub owner details.
4. Post-publish source edit:
   - Editing a source creates draft changes.
   - Live public proof stays available.
   - Publish updates refreshes public proof.
5. Mobile:
   - Topbar remains compact.
   - No text overlap.
   - 3D card flips and stays in frame.

- [ ] **Step 3: Record the acceptance receipt**

Create `docs/goals/prbar-nextjs-client-prototype/notes/signed-in-ux-fixes-qa.md` with:

```markdown
# Signed-In UX Fixes QA

Date: 2026-05-29

## Commands

- `npm run lint` - pass
- `npm run build` - pass
- `npm run smoke` - pass
- `npm run qa` - pass

## Workflows Verified

- Signed-out unpublished proof gates `/profile`, `/card`, `/receipt`, and `/project`.
- Signed-in nav exposes Dashboard, Builder Proof, Sources & Privacy, and Account.
- Signed-in home starts with owner workspace.
- Source review is explicit before first publish.
- Source edits after publish create draft updates without silently removing public proof.
- Public preview hides owner/session/GitHub connection details.
- Share labels distinguish Builder Card from Builder Proof.
- Mobile topbar remains under 132px at 390px width.
- 3D Builder Card is visible, flippable, and framed on mobile and desktop.

## Screenshots

- Add screenshot paths captured during final QA.
```

- [ ] **Step 4: Check git diff scope**

Run:

```bash
cd /Users/neonwatty/Desktop/prbar
git status --short
git diff -- apps/web/app/prototype-app.tsx apps/web/app/globals.css apps/web/smoke-test.js docs/superpowers/plans/2026-05-29-prbar-signed-in-ux-fixes.md
```

Expected:
- Diff is limited to the Next.js prototype, its tests/styles, and this plan/receipt.
- Existing unrelated Swift/mockup changes remain untouched.

## Acceptance Criteria

- Signed-out users cannot inspect unpublished Builder Proof content via `/profile`, `/card`, `/receipt`, or `/project`.
- Signed-in users see `Dashboard`, `Builder Proof`, `Sources & Privacy`, and `Account` in the primary nav.
- Signed-in `/home` starts with a private owner workspace, not the marketing hero.
- Source review is a distinct step and publish is blocked until source choices are confirmed.
- Post-publish source edits are saved as draft updates and do not silently unpublish the live proof.
- Public preview and signed-out public proof never expose owner session/GitHub connection labels.
- Source controls distinguish count mode from public-name visibility.
- Share copy clearly distinguishes Builder Card from Builder Proof.
- Mobile topbar is compact at 390px width and the 3D Builder Card remains framed and flippable.
- `npm run lint`, `npm run build`, `npm run smoke`, and `npm run qa` pass from `/Users/neonwatty/Desktop/prbar/apps/web`.

## Implementation Order

1. Task 1: State-truthful proof route gates.
2. Task 2: Dashboard-first signed-in IA.
3. Task 3: Source review and publish-update model.
4. Task 4: Copy and source-control simplification.
5. Task 5: Mobile and visual polish.
6. Task 6: Final QA receipt.

This order keeps the highest-risk product truth issues ahead of visual polish.
