import Foundation

enum SampleData {
  static let today = date("2026-05-24")

  static func date(_ value: String) -> Date {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: value)!
  }

  static func dateTime(_ value: String) -> Date {
    ISO8601DateFormatter().date(from: value)!
  }

  static let repositories: [Repository] = [
    Repository(id: "prbar", owner: "mean-weasel", name: "prbar", visibility: .public, colorHex: "#0ea5e9", included: true, recommended: true, access: .ready, reason: "Most active this week"),
    Repository(id: "launch-kit", owner: "neonwatty", name: "launch-kit", visibility: .public, colorHex: "#16a34a", included: true, recommended: true, access: .ready, reason: "Recent releases"),
    Repository(id: "client-api", owner: "example", name: "client-api", visibility: .private, colorHex: "#f59e0b", included: true, recommended: true, access: .ready, reason: "Private repo included"),
    Repository(id: "docs-site", owner: "neonwatty", name: "docs-site", visibility: .public, colorHex: "#7c3aed", included: false, recommended: false, access: .ready, reason: "Documentation releases"),
    Repository(id: "ops-console", owner: "example", name: "ops-console", visibility: .private, colorHex: "#ef4444", included: false, recommended: false, access: .sso, reason: "Needs SSO authorization"),
  ]

  static let pullRequests: [PullRequest] = [
    PullRequest(id: "pr-39", title: "Connect GitHub auth fallback", repoID: "prbar", number: 39, mergedAt: dateTime("2026-05-24T17:42:00Z")),
    PullRequest(id: "pr-38", title: "Update GitHub Pages actions", repoID: "prbar", number: 38, mergedAt: dateTime("2026-05-24T16:18:00Z")),
    PullRequest(id: "pr-36", title: "Expand app smoke coverage", repoID: "prbar", number: 36, mergedAt: dateTime("2026-05-23T21:04:00Z")),
    PullRequest(id: "pr-44", title: "Add release smoke harness", repoID: "launch-kit", number: 44, mergedAt: dateTime("2026-05-22T18:20:00Z")),
    PullRequest(id: "pr-77", title: "Harden webhook signature checks", repoID: "client-api", number: 77, mergedAt: dateTime("2026-05-21T15:15:00Z")),
    PullRequest(id: "pr-81", title: "Refresh launch notes template", repoID: "launch-kit", number: 81, mergedAt: dateTime("2026-05-20T12:30:00Z")),
    PullRequest(id: "pr-61", title: "Document release card workflow", repoID: "docs-site", number: 61, mergedAt: dateTime("2026-05-19T10:00:00Z")),
    PullRequest(id: "pr-90", title: "Add incident export view", repoID: "ops-console", number: 90, mergedAt: dateTime("2026-05-18T11:10:00Z")),
  ]

  static let releases: [ReleaseMoment] = [
    ReleaseMoment(id: "rel-prbar-140", repoID: "prbar", title: "GitHub auth fallback", tag: "v1.4.0", date: date("2026-05-24"), source: .release, notes: "Connects GitHub auth fallback, improves live data startup behavior, and preserves the last useful activity view.", url: URL(string: "https://github.com/mean-weasel/prbar/releases/tag/v1.4.0")!),
    ReleaseMoment(id: "rel-prbar-130", repoID: "prbar", title: "Pages deployment cleanup", tag: "v1.3.0", date: date("2026-05-22"), source: .release, notes: "Updates GitHub Pages Actions, refreshes the landing page, and keeps the public preview current.", url: URL(string: "https://github.com/mean-weasel/prbar/releases/tag/v1.3.0")!),
    ReleaseMoment(id: "tag-launch-100", repoID: "launch-kit", title: "Tagged v1.0.0", tag: "v1.0.0", date: date("2026-05-21"), source: .tag, notes: "Generated from merged PRs around this tag: release smoke harness and launch notes template.", url: URL(string: "https://github.com/neonwatty/launch-kit/releases/tag/v1.0.0")!),
    ReleaseMoment(id: "rel-launch-092", repoID: "launch-kit", title: "Smoke test expansion", tag: "v0.9.2", date: date("2026-05-18"), source: .release, notes: "Expands release smoke coverage and adds a clearer fixture baseline for launch checks.", url: URL(string: "https://github.com/neonwatty/launch-kit/releases/tag/v0.9.2")!),
    ReleaseMoment(id: "tag-prbar-121", repoID: "prbar", title: "Tagged v1.2.1", tag: "v1.2.1", date: date("2026-05-16"), source: .tag, notes: "No GitHub Release notes found. PRBar summarized merged PRs around this tag.", url: URL(string: "https://github.com/mean-weasel/prbar/releases/tag/v1.2.1")!),
    ReleaseMoment(id: "rel-client-210", repoID: "client-api", title: "Webhook reliability update", tag: "v2.1.0", date: date("2026-05-14"), source: .release, notes: "Hardens webhook signature checks and adds clearer retry handling for customer integrations.", url: URL(string: "https://github.com/example/client-api/releases/tag/v2.1.0")!),
  ]

  static let activitySnapshot = GitHubActivitySnapshot(
    pullRequests: pullRequests,
    releases: releases,
    anchorDate: today
  )

  static let growthDashboard = GrowthDashboardSnapshot.fixture(range: .week)
}
