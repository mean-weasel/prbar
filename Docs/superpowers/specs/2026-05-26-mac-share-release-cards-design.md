# PRBar Mac Share And Release Cards Design

## Purpose

Add iOS-inspired share cards and release notes to the macOS menu bar app without turning the popover into a full card studio.

The Mac v1 should keep PRBar compact and action-oriented:

1. Inspect PR activity or release notes in the menu bar.
2. Click a source-specific share action.
3. Review a fixed card preview.
4. Share, copy, or save the generated image.

The design intentionally avoids a separate Share tab in v1. Share is an action attached to the work being viewed.

## Product Shape

The popover should have three primary tabs:

- Activity
- Releases
- Settings

Activity remains the default tab. Releases becomes the new shipping-moments surface. Settings keeps repository inclusion, refresh behavior, and future privacy defaults.

There is no dedicated Share tab for Mac v1.

## Activity Share Flow

Activity gets a `Share PR Card` action.

The action creates a fixed PR-period card from the current Activity state:

- selected time window
- selected binning where relevant
- included repositories
- total merged pull requests
- active repository count
- compact activity chart
- repo mix or top repositories
- PRBar mark

Clicking `Share PR Card` opens a compact preview/export sheet instead of immediately opening the native share sheet.

Preview sheet contents:

- rendered PR card image
- short privacy/defaults status row
- primary `Share` action
- secondary `Copy Image` action
- secondary `Save PNG` action

The preview is not customizable in v1. It is a confirmation and export surface.

## Release Notes Flow

Add a Releases tab that lists shipping moments from included repositories.

The first production model should prefer official GitHub Releases. Tagged versions without GitHub Release notes may appear as fallback shipping moments only if they are clearly labeled as tag-derived summaries.

Release rows should show:

- repository
- tag or version
- release title
- date
- source badge: `Release` or `Tag`
- short notes preview

Selecting a release shows:

- title and tag
- repository and date
- original release notes for GitHub Releases
- generated tag summary for tag fallback items, clearly labeled
- `Share Release Card`
- optional `Copy Notes`
- optional `Open on GitHub`

`Share Release Card` opens the same compact preview/export sheet pattern as Activity, but renders the fixed release-card format.

The release-card image should include:

- release or tag title
- repository, subject to privacy defaults
- date or range, subject to privacy defaults
- release notes excerpt
- source label that distinguishes official GitHub Release notes from generated tag summaries
- PRBar mark

## Preview And Export

Both card types must show a preview before export.

Rationale:

- share cards are public-facing
- repository names, client work, exact counts, links, and release-note excerpts can be sensitive
- fixed card formats still need a final visual check before leaving the app

Export actions:

- `Share`: open the native macOS share sheet for the rendered image
- `Copy Image`: copy the rendered image to the pasteboard
- `Save PNG`: save the rendered image through a standard save panel

Caption generation is out of scope for the first Mac version.

## Settings And Privacy

Per-share customization is out of scope for v1.

Settings may hold global defaults that affect generated cards:

- show or hide GitHub handle
- show or hide repository names
- show exact or rounded PR counts
- show or hide private repository labels
- default card visual style

If these settings are not implemented with the first release of the feature, the card renderer should choose conservative defaults:

- hide private repository names
- avoid private repo titles in public text
- show exact counts only for currently visible aggregate activity
- clearly label tag-derived summaries

## Non-Goals

Mac v1 does not include:

- a dedicated Share tab
- per-share card editing
- multiple card themes in the popover
- saved card gallery
- public/evidence card sides
- AI-generated release notes presented as official notes
- public PRBar profiles or publishing

These remain possible later once the fixed-card flows prove useful.

## Implementation Notes

The implementation should follow the existing SwiftUI popover structure:

- Extend `PRPopoverView` to add a `Releases` tab between Activity and Settings.
- Keep the popover width close to the current 460-point design unless release notes require a modest increase.
- Add source-specific share buttons in Activity and Releases.
- Use a shared preview/export sheet component for both PR cards and release cards.
- Keep rendering logic separate from popover views so it can be unit-tested and reused.
- Store release data separately from PR activity data.
- Reuse included repository settings to scope both Activity and Releases.

The release data model should be designed for real GitHub API data, even if the first local implementation uses sample data or fixtures.

Suggested model boundaries:

- `ReleaseMoment`: repo id, title, tag, date, notes, URL, source type
- `ReleaseMomentProvider`: fetches releases and tag fallbacks
- `ShareCardRenderer`: renders source-specific card images
- `ShareCardPreviewSheet`: previews and exports rendered images

## Testing

Unit tests should cover:

- release moments are filtered by included repositories
- official releases and tag fallbacks are labeled distinctly
- PR card payloads reflect current Activity window and repository inclusion
- release card payloads include the selected release metadata
- privacy defaults remove private repository names where required

UI or smoke coverage should verify:

- Activity exposes `Share PR Card`
- Releases exposes release rows and `Share Release Card`
- preview sheet appears before export
- preview sheet offers Share, Copy Image, and Save PNG actions

Native share-sheet, pasteboard, and save-panel behavior may need focused integration tests or manual smoke coverage because they cross app and system UI boundaries.
