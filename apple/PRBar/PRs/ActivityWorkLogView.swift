import SwiftUI

struct ActivityWorkLogView: View {
  var rows: [ActivityWorkRow]
  var emptyDetail: String

  @State private var selectedFilter = ActivityWorkFilter.all

  private var filteredRows: [ActivityWorkRow] {
    rows.filter(selectedFilter.includes)
  }

  private var pullRequestCount: Int {
    rows.filter { $0.kind == .pullRequest }.count
  }

  private var releaseCount: Int {
    rows.filter { $0.kind == .release }.count
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        header
        summaryMetrics

        if rows.isEmpty {
          emptyState(detail: emptyDetail)
        } else {
          filterPicker
          workRowsSection
        }
      }
      .padding()
      .padding(.bottom, PRBarTheme.tabContentBottomPadding)
    }
    .navigationTitle("Work log")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Work log")
        .font(.largeTitle.weight(.bold))

      Text("Detailed pull requests, tags, and releases from the selected repositories.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var summaryMetrics: some View {
    HStack(spacing: 10) {
      WorkLogMetric(
        value: "\(rows.count)",
        label: rows.count == 1 ? "Item" : "Items",
        systemImage: "list.bullet.rectangle"
      )
      .accessibilityIdentifier("activity-work-log-total")

      WorkLogMetric(
        value: "\(pullRequestCount)",
        label: pullRequestCount == 1 ? "PR" : "PRs",
        systemImage: "arrow.triangle.pull"
      )

      WorkLogMetric(
        value: "\(releaseCount)",
        label: releaseCount == 1 ? "Release" : "Releases",
        systemImage: "tag"
      )
    }
  }

  private var filterPicker: some View {
    Picker("Work type", selection: $selectedFilter) {
      ForEach(ActivityWorkFilter.allCases) { filter in
        Text(filter.title).tag(filter)
      }
    }
    .pickerStyle(.segmented)
    .accessibilityIdentifier("activity-work-log-filter")
  }

  private var workRowsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(selectedFilter.sectionTitle)
        .font(.title3.weight(.bold))

      if filteredRows.isEmpty {
        emptyState(detail: selectedFilter.emptyDetail)
      } else {
        VStack(spacing: 10) {
          ForEach(filteredRows) { row in
            ActivityWorkRowView(row: row, dateLabel: shortDateLabel(for: row.happenedAt))
          }
        }
      }
    }
  }

  private func emptyState(detail: String) -> some View {
    ActivityEmptyStateView(
      title: "No recent activity",
      detail: detail,
      systemImage: "tray",
      identifier: "activity-empty-state"
    )
  }

  private func shortDateLabel(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "MMM d"
    return formatter.string(from: date)
  }
}

struct ActivityWorkRow: Identifiable {
  var id: String
  var kind: ActivityWorkKind
  var title: String
  var repositoryName: String
  var happenedAt: Date
  var systemImage: String
}

enum ActivityWorkKind {
  case pullRequest
  case release

  var title: String {
    switch self {
    case .pullRequest:
      return "PR"
    case .release:
      return "Release"
    }
  }
}

private enum ActivityWorkFilter: CaseIterable, Identifiable {
  case all
  case pullRequests
  case releases

  var id: Self { self }

  var title: String {
    switch self {
    case .all:
      return "All"
    case .pullRequests:
      return "PRs"
    case .releases:
      return "Releases"
    }
  }

  var sectionTitle: String {
    switch self {
    case .all:
      return "Recent work"
    case .pullRequests:
      return "Pull requests"
    case .releases:
      return "Releases and tags"
    }
  }

  var emptyDetail: String {
    switch self {
    case .all:
      return "Recent work will appear here after activity sync."
    case .pullRequests:
      return "No merged pull requests were found in this activity window."
    case .releases:
      return "No releases or tags were found in this activity window."
    }
  }

  func includes(_ row: ActivityWorkRow) -> Bool {
    switch self {
    case .all:
      return true
    case .pullRequests:
      return row.kind == .pullRequest
    case .releases:
      return row.kind == .release
    }
  }
}

private struct WorkLogMetric: View {
  var value: String
  var label: String
  var systemImage: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Image(systemName: systemImage)
        .font(.caption.weight(.semibold))
        .foregroundStyle(PRBarTheme.accent)

      Text(value)
        .font(.title2.weight(.bold))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.75)

      Text(label)
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .prbarSurface()
  }
}

private struct ActivityWorkRowView: View {
  var row: ActivityWorkRow
  var dateLabel: String

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      Image(systemName: row.systemImage)
        .font(.caption.weight(.semibold))
        .foregroundStyle(PRBarTheme.accent)
        .frame(width: 24, height: 24)
        .background(PRBarTheme.accent.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

      VStack(alignment: .leading, spacing: 3) {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(row.kind.title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
          Text(dateLabel)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Text(row.title)
          .font(.subheadline.weight(.semibold))
          .lineLimit(3)

        Text(row.repositoryName)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 8)
    .prbarSurface()
  }
}
