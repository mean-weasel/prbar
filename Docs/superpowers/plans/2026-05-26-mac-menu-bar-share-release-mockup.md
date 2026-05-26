# Mac Menu Bar Share Release Mockup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an interactive HTML/CSS/JS mockup of the updated PRBar Mac menu bar popover with Activity, Releases, Settings, fixed share-card previews, and export actions.

**Architecture:** Create a standalone static prototype under `mockups/mac-menu-bar`. Keep markup, styling, and stateful interactions split across `index.html`, `styles.css`, and `app.js`. Use fixture data and local state only; no GitHub calls.

**Tech Stack:** Plain HTML, CSS, and vanilla JavaScript.

---

### Task 1: Static Prototype Shell

**Files:**
- Create: `mockups/mac-menu-bar/index.html`
- Create: `mockups/mac-menu-bar/styles.css`
- Create: `mockups/mac-menu-bar/app.js`
- Create: `mockups/mac-menu-bar/README.md`

- [ ] **Step 1: Add the HTML entry file**

Create `index.html` with a page wrapper, a Mac menu bar strip, a popover frame, and a root element:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>PRBar Mac Menu Bar Share Prototype</title>
  <link rel="stylesheet" href="./styles.css">
</head>
<body>
  <main class="page">
    <section class="stage" aria-label="Interactive Mac menu bar mockup">
      <div class="desktop">
        <div class="menu-bar">
          <div class="menu-left"><strong>PRBar</strong><span>File</span><span>Edit</span><span>View</span></div>
          <div class="menu-right"><button id="menuButton" class="status-item">28 PRs</button><span>Tue 9:42 AM</span></div>
        </div>
        <div id="app" class="popover" aria-live="polite"></div>
      </div>
    </section>
  </main>
  <script src="./app.js"></script>
</body>
</html>
```

- [ ] **Step 2: Add stateful rendering**

Implement `app.js` with fixture repositories, releases, tab state, selected release state, share-preview state, and handlers for:

- switching Activity, Releases, and Settings tabs
- changing Activity range
- selecting releases
- opening PR and release card previews
- closing previews
- simulating Share, Copy Image, and Save PNG export success states
- toggling repository inclusion in Settings

- [ ] **Step 3: Add polished CSS**

Implement `styles.css` with a compact Mac-style popover, dense tabs, charts, release rows, preview sheet, fixed card designs, export actions, responsive behavior, and no placeholder boxes.

- [ ] **Step 4: Add README**

Document how to open the prototype and list the interactive states.

### Task 2: Verification

**Files:**
- Verify: `mockups/mac-menu-bar/index.html`
- Verify: `mockups/mac-menu-bar/app.js`
- Verify: `mockups/mac-menu-bar/styles.css`

- [ ] **Step 1: Run a static server**

Run:

```bash
python3 -m http.server 5174 --directory mockups/mac-menu-bar
```

Expected: server listens at `http://localhost:5174`.

- [ ] **Step 2: Browser check**

Open `http://localhost:5174` and verify:

- Activity is the default tab.
- `Share PR Card` opens a PR card preview before export actions.
- Releases tab shows release rows, release notes, and `Share Release Card`.
- `Share Release Card` opens a release card preview before export actions.
- Settings repository toggles affect visible Activity and Release content.

- [ ] **Step 3: Responsive check**

Verify at desktop and narrow viewport widths that the popover remains readable and no button text overlaps.
