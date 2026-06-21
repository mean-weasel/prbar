import SwiftUI

struct PRRepositoryDetailView: View {
  var repository: Repository?
  var pullRequests: [PullRequest]
  var anchorDate: Date
  var range: ActivityRange

  @State private var selectedDate: Date

  init(
    repository: Repository?,
    pullRequests: [PullRequest],
    anchorDate: Date,
    range: ActivityRange
  ) {
    self.repository = repository
    self.pullRequests = pullRequests
    self.anchorDate = anchorDate
    self.range = range
    self._selectedDate = State(initialValue: Self.defaultSelectedDate(
      pullRequests: pullRequests,
      anchorDate: anchorDate,
      range: range
    ))
  }

  private var sortedPullRequests: [PullRequest] {
    pullRequests.sorted { $0.mergedAt > $1.mergedAt }
  }

  private var calendarDays: [CalendarDay] {
    CalendarDay.days(endingAt: anchorDate, range: range).map { day in
      CalendarDay(date: day.date, count: pullRequests(on: day.date).count)
    }
  }

  private var selectedPullRequests: [PullRequest] {
    pullRequests(on: selectedDate)
  }

  private var pullRequestSignature: String {
    sortedPullRequests
      .map { "\($0.id):\($0.mergedAt.timeIntervalSince1970)" }
      .joined(separator: "|")
  }

  private var activeDayCount: Int {
    Set(pullRequests.map { calendar.startOfDay(for: $0.mergedAt) }).count
  }

  private var repositoryFullName: String {
    repository?.fullName ?? "Repository"
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        header
        metrics
        distributionSection
        selectedDaySection
        recentPRs
      }
      .padding()
    }
    .navigationTitle(repository?.name ?? "Repository")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      resetSelectedDate()
    }
    .onChange(of: repository?.id) { _, _ in
      resetSelectedDate()
    }
    .onChange(of: anchorDate) { _, _ in
      resetSelectedDate()
    }
    .onChange(of: range) { _, _ in
      resetSelectedDate()
    }
    .onChange(of: pullRequestSignature) { _, _ in
      resetSelectedDate()
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Repo activity")
        .font(.largeTitle.weight(.bold))
      Text(repositoryFullName)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
  }

  private var metrics: some View {
    HStack(spacing: 10) {
      RepoActivityMetric(
        text: "\(pullRequests.count) merged",
        systemImage: "arrow.triangle.pull"
      )

      RepoActivityMetric(
        text: "\(activeDayCount) \(activeDayCount == 1 ? "active day" : "active days")",
        systemImage: "calendar"
      )
    }
  }

  @ViewBuilder
  private var distributionSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      VStack(alignment: .leading, spacing: 4) {
        Text("PR distribution")
          .font(.headline)

        Text("\(range.windowLabel) by merge date")
          .font(.caption)
          .foregroundStyle(.secondary)

        Text("Pick a bar to inspect daily PRs.")
          .font(.caption)
          .foregroundStyle(.secondary)

        Text(busiestDaySummary)
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
      }

      if range == .month {
        MonthHeatMapView(days: calendarDays, selectedDate: $selectedDate, countLabel: pullRequestCountLabel)
      } else {
        RepoPRDistributionChart(days: calendarDays, selectedDate: $selectedDate, countLabel: pullRequestCountLabel)
      }
    }
  }

  private var selectedDaySection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("\(selectedPullRequests.count) merged on \(monthDayLabel(for: selectedDate))")
        .font(.title3.weight(.bold))

      if selectedPullRequests.isEmpty {
        ActivityEmptyStateView(
          title: "No PRs merged",
          detail: "Choose a day with repo activity.",
          systemImage: "arrow.triangle.pull",
          identifier: "repo-selected-day-empty-state"
        )
      } else {
        VStack(spacing: 10) {
          ForEach(selectedPullRequests) { pullRequest in
            RepoActivityPullRequestRow(pullRequest: pullRequest, dateLabel: shortDateLabel(for: pullRequest.mergedAt))
          }
        }
      }
    }
  }

  private var recentPRs: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Recent PRs")
        .font(.headline)

      if sortedPullRequests.isEmpty {
        ActivityEmptyStateView(
          title: "No merged PRs",
          detail: "Merged pull requests for this repository will appear here after activity sync.",
          systemImage: "arrow.triangle.pull",
          identifier: "repo-prs-empty-state"
        )
      } else {
        VStack(spacing: 10) {
          ForEach(sortedPullRequests.prefix(8)) { pullRequest in
            RepoActivityPullRequestRow(pullRequest: pullRequest, dateLabel: shortDateLabel(for: pullRequest.mergedAt))
          }
        }
      }
    }
  }

  private func pullRequests(on date: Date) -> [PullRequest] {
    sortedPullRequests.filter { CalendarDay.isSameDay($0.mergedAt, date) }
  }

  private var busiestDaySummary: String {
    guard let busiestDay = calendarDays.max(by: { $0.count < $1.count }), busiestDay.count > 0 else {
      return "No merged PRs in this window yet."
    }

    let countText = busiestDay.count == 1 ? "1 merged PR" : "\(busiestDay.count) merged PRs"
    return "\(monthDayLabel(for: busiestDay.date)) was busiest with \(countText)."
  }

  private func monthDayLabel(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = calendar.timeZone
    formatter.dateFormat = "MMMM d"
    return formatter.string(from: date)
  }

  private func shortDateLabel(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = calendar.timeZone
    formatter.dateFormat = "MMM d"
    return formatter.string(from: date)
  }

  private func pullRequestCountLabel(for count: Int) -> String {
    count == 1 ? "pull request" : "pull requests"
  }

  private var calendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }

  private func resetSelectedDate() {
    selectedDate = Self.defaultSelectedDate(
      pullRequests: pullRequests,
      anchorDate: anchorDate,
      range: range
    )
  }

  private static func defaultSelectedDate(
    pullRequests: [PullRequest],
    anchorDate: Date,
    range: ActivityRange
  ) -> Date {
    let days = visibleDays(pullRequests: pullRequests, anchorDate: anchorDate, range: range)

    if let newestActiveDay = days.last(where: { $0.count > 0 }) {
      return newestActiveDay.date
    }

    if days.contains(where: { CalendarDay.isSameDay($0.date, anchorDate) }) {
      return anchorDate
    }

    return days.last?.date ?? anchorDate
  }

  private static func visibleDays(
    pullRequests: [PullRequest],
    anchorDate: Date,
    range: ActivityRange
  ) -> [CalendarDay] {
    CalendarDay.days(endingAt: anchorDate, range: range).map { day in
      CalendarDay(
        date: day.date,
        count: pullRequests.filter { CalendarDay.isSameDay($0.mergedAt, day.date) }.count
      )
    }
  }
}

private struct RepoActivityMetric: View {
  var text: String
  var systemImage: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Image(systemName: systemImage)
        .font(.caption.weight(.semibold))
        .foregroundStyle(PRBarTheme.accent)

      Text(text)
        .font(.title2.weight(.bold))
        .monospacedDigit()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .prbarSurface()
  }
}

private struct RepoPRDistributionChart: View {
  var days: [CalendarDay]
  @Binding var selectedDate: Date
  var countLabel: (Int) -> String

  private var maxCount: Int {
    max(days.map(\.count).max() ?? 1, 1)
  }

  var body: some View {
    HStack(alignment: .bottom, spacing: 8) {
      ForEach(days) { day in
        let isSelected = CalendarDay.isSameDay(day.date, selectedDate)

        Button {
          selectedDate = day.date
        } label: {
          VStack(spacing: 7) {
            Text(day.count > 0 ? "\(day.count)" : "0")
              .font(.caption2.weight(.semibold))
              .monospacedDigit()
              .foregroundStyle(isSelected ? PRBarTheme.accent : .secondary)

            RoundedRectangle(cornerRadius: 5, style: .continuous)
              .fill(barColor(for: day, isSelected: isSelected))
              .frame(height: barHeight(for: day))
              .frame(maxHeight: .infinity, alignment: .bottom)

            Text("\(day.dayNumber)")
              .font(.caption2)
              .foregroundStyle(.secondary)
              .monospacedDigit()
          }
          .frame(maxWidth: .infinity)
          .frame(height: 126, alignment: .bottom)
          .padding(.horizontal, 4)
          .padding(.vertical, 8)
          .background(isSelected ? PRBarTheme.selectedSurfaceBackground : PRBarTheme.surfaceBackground)
          .clipShape(RoundedRectangle(cornerRadius: PRBarTheme.surfaceCornerRadius, style: .continuous))
          .overlay {
            RoundedRectangle(cornerRadius: PRBarTheme.surfaceCornerRadius, style: .continuous)
              .stroke(isSelected ? PRBarTheme.accent.opacity(0.65) : Color.clear, lineWidth: 1)
        }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.accessibilityLabel(isSelected: isSelected, countLabel: countLabel))
      }
    }
    .frame(height: 126)
  }

  private func barHeight(for day: CalendarDay) -> CGFloat {
    guard day.count > 0 else {
      return 8
    }

    return max(12, CGFloat(day.count) / CGFloat(maxCount) * 70)
  }

  private func barColor(for day: CalendarDay, isSelected: Bool) -> AnyShapeStyle {
    if isSelected {
      return AnyShapeStyle(PRBarTheme.accent.gradient)
    }

    if day.count > 0 {
      return AnyShapeStyle(PRBarTheme.accent.opacity(0.65).gradient)
    }

    return AnyShapeStyle(Color(.tertiarySystemFill))
  }
}

private struct RepoActivityPullRequestRow: View {
  var pullRequest: PullRequest
  var dateLabel: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("#\(pullRequest.number) \(pullRequest.title)")
        .font(.subheadline.weight(.semibold))
      Text(dateLabel)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .prbarSurface()
  }
}

#Preview {
  NavigationStack {
    PRRepositoryDetailView(
      repository: SampleData.repositories[0],
      pullRequests: SampleData.pullRequests.filter { $0.repoID == "prbar" },
      anchorDate: SampleData.today,
      range: .week
    )
  }
}
