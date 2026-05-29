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

- Not captured in this run; regression coverage was command-driven through Playwright smoke and parity QA.
