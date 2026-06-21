import SwiftUI

struct PRsView: View {
  @Bindable var store: PRBarStore

  private var calendarDays: [CalendarDay] {
    CalendarDay.days(endingAt: store.activityAnchorDate, range: store.prRange).map { day in
      CalendarDay(date: day.date, count: pullRequests(on: day.date).count)
    }
  }

  private var selectedPullRequests: [PullRequest] {
    pullRequests(on: store.selectedPRDate)
  }

  private var releaseCalendarDays: [CalendarDay] {
    CalendarDay.days(endingAt: store.activityAnchorDate, range: store.releaseRange).map { day in
      CalendarDay(date: day.date, count: releases(on: day.date).count)
    }
  }

  private var selectedRelease: ReleaseMoment? {
    releases(on: store.selectedReleaseDate).first
      ?? store.releases.first { $0.id == store.selectedReleaseID }
  }

  private var includedPullRequests: [PullRequest] {
    let includedIDs = Set(store.includedRepositories.map(\.id))
    return store.pullRequests
      .filter { includedIDs.contains($0.repoID) }
      .sorted { $0.mergedAt > $1.mergedAt }
  }

  private var groupedReleases: [(date: Date, releases: [ReleaseMoment])] {
    let includedIDs = Set(store.includedRepositories.map(\.id))
    let grouped = Dictionary(grouping: store.releases.filter { includedIDs.contains($0.repoID) }) { release in
      fixtureCalendar.startOfDay(for: release.date)
    }

    return grouped
      .map { (date: $0.key, releases: $0.value.sorted { $0.date > $1.date }) }
      .sorted { $0.date > $1.date }
  }

  private var chartDays: [DailyPRChartDay] {
    calendarDays.map { day in
      DailyPRChartDay(
        day: day,
        segments: store.includedRepositories.compactMap { repository in
          let count = store.pullRequests.filter {
            $0.repoID == repository.id && CalendarDay.isSameDay($0.mergedAt, day.date)
          }.count

          guard count > 0 else {
            return nil
          }

          return DailyPRChartSegment(
            repositoryID: repository.id,
            count: count,
            color: PRBarTheme.repositoryColor(repository.colorHex)
          )
        }
      )
    }
  }

  private var repoRows: [RepoDistributionRow] {
    store.includedRepositories.map { repository in
      RepoDistributionRow(
        repository: repository,
        count: store.pullRequests.filter { $0.repoID == repository.id }.count
      )
    }
    .filter { $0.count > 0 }
    .sorted { $0.count > $1.count }
  }

  private var latestWorkRows: [ActivityWorkRow] {
    let pullRequestRows = includedPullRequests.map { pullRequest in
      ActivityWorkRow(
        id: "pr-\(pullRequest.id)",
        kind: "PR",
        title: "#\(pullRequest.number) \(pullRequest.title)",
        repositoryName: repository(for: pullRequest.repoID)?.name ?? pullRequest.repoID,
        happenedAt: pullRequest.mergedAt,
        systemImage: "arrow.triangle.pull"
      )
    }

    let releaseRows = groupedReleases.flatMap { group in
      group.releases.map { release in
        ActivityWorkRow(
          id: "release-\(release.id)",
          kind: "Release",
          title: "\(release.tag) \(release.title)",
          repositoryName: repository(for: release.repoID)?.name ?? release.repoID,
          happenedAt: release.date,
          systemImage: "tag"
        )
      }
    }

    return Array((pullRequestRows + releaseRows).sorted { $0.happenedAt > $1.happenedAt }.prefix(8))
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 22) {
          if shouldPromoteSyncStatus {
            syncStatus
          }

          header
          pulseSection
          cadenceSection
          workLogEntrySection

          if shouldPromoteSyncStatus == false {
            syncStatus
          }
        }
        .padding()
      }
      .refreshable {
        await store.refreshActivity()
      }
      .navigationTitle("Activity")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            Task {
              await store.refreshActivity()
            }
          } label: {
            Label("Refresh activity", systemImage: "arrow.clockwise")
          }
          .disabled(store.isRefreshingActivity)
        }
      }
      .navigationDestination(for: Repository.ID.self) { repositoryID in
        PRRepositoryDetailView(
          repository: repository(for: repositoryID),
          pullRequests: store.pullRequests.filter { $0.repoID == repositoryID },
          anchorDate: store.activityAnchorDate,
          range: store.prRange
        )
      }
    }
  }

  private var syncStatus: some View {
    ActivitySyncStatusView(
      isRefreshing: store.isRefreshingActivity,
      context: store.activityRefreshContext,
      progress: store.activityRefreshProgress,
      lastRefreshedAt: store.lastActivityRefreshAt,
      lastRefreshAttemptAt: store.lastActivityRefreshAttemptAt,
      issue: store.activityRefreshIssue,
      repositoryIssues: store.activityRepositoryIssues,
      isSampleData: store.isUsingSampleData
    )
  }

  private var shouldPromoteSyncStatus: Bool {
    store.isRefreshingActivity || store.activityRefreshIssue != nil || store.activityRepositoryIssues.isEmpty == false
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Text("Shipping rhythm")
          .font(.largeTitle.weight(.bold))
        Text("What shipped today, this week, and most recently.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      RepositoryEditLink(store: store)
    }
  }

  private var pulseSection: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Shipping snapshot")
            .font(.title3.weight(.bold))
          Text(snapshotSummary)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer()

        Text(store.activitySourceLabel)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(store.isUsingSampleData ? PRBarTheme.accent : .secondary)
          .padding(.horizontal, 8)
          .padding(.vertical, 5)
          .background((store.isUsingSampleData ? PRBarTheme.accent : Color.secondary).opacity(0.10))
          .clipShape(Capsule())
      }

      HStack(spacing: 10) {
        ActivitySummaryMetric(
          value: "\(selectedPullRequests.count)",
          label: "Merged",
          systemImage: "arrow.triangle.pull"
        )

        ActivitySummaryMetric(
          value: "\(releases(on: store.selectedReleaseDate).count)",
          label: "Releases",
          systemImage: "tag"
        )
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .prbarSurface()
  }

  private var snapshotSummary: String {
    let pullRequestText = selectedPullRequests.count == 1 ? "1 PR" : "\(selectedPullRequests.count) PRs"
    let releaseCount = releases(on: store.selectedReleaseDate).count
    let releaseText = releaseCount == 1 ? "1 release" : "\(releaseCount) releases"
    return "\(pullRequestText) merged and \(releaseText) visible in this rhythm window."
  }

  @ViewBuilder
  private var prCalendar: some View {
    if store.prRange == .month {
      MonthHeatMapView(days: calendarDays, selectedDate: $store.selectedPRDate, countLabel: pullRequestCountLabel)
    } else {
      CalendarStripView(days: calendarDays, selectedDate: $store.selectedPRDate, countLabel: pullRequestCountLabel)
    }
  }

  private var cadenceSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      ActivitySectionHeader(
        title: "This week's cadence",
        detail: "Merged PRs and release moments across included repositories."
      )

      RangePickerView(selection: $store.prRange)
      prCalendar
      selectedDayMetric
      DailyPRBarChart(days: chartDays)
      RepoDistributionView(rows: repoRows)
      releaseCadenceEntrySection
    }
  }

  private var releaseCadenceEntrySection: some View {
    NavigationLink {
      ActivityReleaseCadenceView(store: store)
    } label: {
      HStack(alignment: .center, spacing: 12) {
        Image(systemName: "tag")
          .font(.headline.weight(.semibold))
          .foregroundStyle(PRBarTheme.accent)
          .frame(width: 34, height: 34)
          .background(PRBarTheme.accent.opacity(0.10))
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

        VStack(alignment: .leading, spacing: 4) {
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("Release cadence")
              .font(.headline)
              .foregroundStyle(.primary)

            Text(releaseCadenceSummary)
              .font(.caption.weight(.semibold))
              .foregroundStyle(.secondary)
          }

          Text(selectedReleaseSummary)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer(minLength: 8)

        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .prbarSurface()
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("activity-release-cadence-entry")
    .accessibilityLabel("Release cadence")
    .accessibilityHint("Shows release and tag timing details.")
  }

  @ViewBuilder
  private var releaseCalendar: some View {
    Group {
      if store.releaseRange == .month {
        MonthHeatMapView(days: releaseCalendarDays, selectedDate: $store.selectedReleaseDate, countLabel: releaseCountLabel)
      } else {
        CalendarStripView(days: releaseCalendarDays, selectedDate: $store.selectedReleaseDate, countLabel: releaseCountLabel)
      }
    }
    .onChange(of: store.selectedReleaseDate) { _, date in
      store.selectedReleaseID = releases(on: date).first?.id
    }
  }

  @ViewBuilder
  private var selectedReleaseCard: some View {
    if let selectedRelease {
      VStack(alignment: .leading, spacing: 10) {
        Text("Selected release")
          .font(.headline)

        Text("\(selectedRelease.tag) \(selectedRelease.title)")
          .font(.title3.weight(.bold))

        Text(repository(for: selectedRelease.repoID)?.name ?? selectedRelease.repoID)
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Text(selectedRelease.notes)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .prbarSurface()
    } else {
      ActivityEmptyStateView(
        title: "No release selected",
        detail: selectedReleaseEmptyDetail,
        systemImage: "tag",
        identifier: "selected-release-empty-state"
      )
    }
  }

  private var workLogEntrySection: some View {
    NavigationLink {
      ActivityWorkLogView(rows: latestWorkRows, emptyDetail: latestWorkEmptyDetail)
    } label: {
      HStack(alignment: .center, spacing: 12) {
        Image(systemName: "list.bullet.rectangle")
          .font(.headline.weight(.semibold))
          .foregroundStyle(PRBarTheme.accent)
          .frame(width: 34, height: 34)
          .background(PRBarTheme.accent.opacity(0.10))
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

        VStack(alignment: .leading, spacing: 4) {
          Text("Work log")
            .font(.headline)
            .foregroundStyle(.primary)

          Text(workLogSummary)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer(minLength: 8)

        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .prbarSurface()
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("activity-work-log-entry")
    .accessibilityLabel("Work log")
    .accessibilityHint("Shows detailed pull requests, tags, and releases.")
  }

  private var selectedDayMetric: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(shortDateLabel(for: store.selectedPRDate))
        .font(.subheadline)
        .foregroundStyle(.secondary)
      Text("\(selectedPullRequests.count) merged")
        .font(.title2.weight(.bold))
        .monospacedDigit()
      if selectedPullRequests.isEmpty {
        Text("No PRs merged on this day.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .prbarSurface()
  }

  private func pullRequests(on date: Date) -> [PullRequest] {
    let includedIDs = Set(store.includedRepositories.map(\.id))
    return store.pullRequests.filter {
      includedIDs.contains($0.repoID) && CalendarDay.isSameDay($0.mergedAt, date)
    }
  }

  private func releases(on date: Date) -> [ReleaseMoment] {
    let includedIDs = Set(store.includedRepositories.map(\.id))
    return store.releases.filter {
      includedIDs.contains($0.repoID) && CalendarDay.isSameDay($0.date, date)
    }
  }

  private func repository(for id: Repository.ID) -> Repository? {
    store.repositories.first { $0.id == id }
  }

  private func shortDateLabel(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "MMM d"
    return formatter.string(from: date)
  }

  private func longDateLabel(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "MMMM d"
    return formatter.string(from: date)
  }

  private func pullRequestCountLabel(for count: Int) -> String {
    count == 1 ? "pull request" : "pull requests"
  }

  private func releaseCountLabel(for count: Int) -> String {
    count == 1 ? "release" : "releases"
  }

  private var selectedReleaseEmptyDetail: String {
    if store.includedRepositories.isEmpty {
      return "Choose repos before looking for release details."
    }
    if store.isRefreshingActivity {
      return "Syncing included repositories. Release details will appear when refresh finishes."
    }
    return "Choose a day with releases or refresh GitHub activity."
  }

  private var releaseRowsEmptyTitle: String {
    if store.includedRepositories.isEmpty {
      return "No repos selected"
    }
    return "No releases or tags"
  }

  private var releaseRowsEmptyDetail: String {
    if store.includedRepositories.isEmpty {
      return "Choose repos to decide which GitHub releases and tags PRBar should sync."
    }
    if store.isRefreshingActivity {
      return "Syncing included repositories. Releases and tags will appear here when refresh finishes."
    }
    if store.activityRepositoryIssues.isEmpty == false {
      return "Synced available repositories, but none published releases or tags yet. Review the partial sync note above."
    }
    if store.activityRefreshIssue != nil {
      return "Refresh did not finish. Existing release data stays visible when available."
    }
    if store.lastActivityRefreshAt != nil {
      return "Selected repos did not publish releases or tags in this window."
    }
    return "Refresh GitHub activity to load releases and tags for selected repos."
  }

  private var releaseCadenceSummary: String {
    let count = releaseCalendarDays.reduce(0) { $0 + $1.count }
    return count == 1 ? "1 release" : "\(count) releases"
  }

  private var selectedReleaseSummary: String {
    guard let selectedRelease else {
      return selectedReleaseEmptyDetail
    }

    return "\(selectedRelease.tag) \(selectedRelease.title)"
  }

  private var latestWorkEmptyDetail: String {
    if store.includedRepositories.isEmpty {
      return "Choose repos to decide which GitHub activity PRBar should sync."
    }
    if store.isRefreshingActivity {
      return "Syncing included repositories. Recent work will appear when refresh finishes."
    }
    if store.lastActivityRefreshAt != nil {
      return "No PRs, tags, or releases were found in selected repos for this window."
    }
    return "Refresh GitHub activity to load recent work from selected repos."
  }

  private var workLogSummary: String {
    guard latestWorkRows.isEmpty == false else {
      return latestWorkEmptyDetail
    }

    let itemText = latestWorkRows.count == 1 ? "1 recent item" : "\(latestWorkRows.count) recent items"
    return "\(itemText) across pull requests, tags, and releases."
  }

  private var fixtureCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }
}

private struct ActivityReleaseCadenceView: View {
  @Bindable var store: PRBarStore

  private var releaseCalendarDays: [CalendarDay] {
    CalendarDay.days(endingAt: store.activityAnchorDate, range: store.releaseRange).map { day in
      CalendarDay(date: day.date, count: releases(on: day.date).count)
    }
  }

  private var selectedRelease: ReleaseMoment? {
    releases(on: store.selectedReleaseDate).first
      ?? store.releases.first { $0.id == store.selectedReleaseID }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        header
        releaseSummary
        RangePickerView(selection: $store.releaseRange)
        releaseCalendar
        selectedReleaseCard
      }
      .padding()
    }
    .navigationTitle("Release cadence")
    .navigationBarTitleDisplayMode(.inline)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Release cadence")
        .font(.largeTitle.weight(.bold))
      Text("Release and tag timing across included repositories.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }

  private var releaseSummary: some View {
    HStack(spacing: 10) {
      ActivitySummaryMetric(
        value: releaseCadenceSummary,
        label: store.releaseRange.windowLabel,
        systemImage: "tag"
      )

      ActivitySummaryMetric(
        value: selectedReleaseDateLabel,
        label: "Selected",
        systemImage: "calendar"
      )
    }
  }

  @ViewBuilder
  private var releaseCalendar: some View {
    Group {
      if store.releaseRange == .month {
        MonthHeatMapView(days: releaseCalendarDays, selectedDate: $store.selectedReleaseDate, countLabel: releaseCountLabel)
      } else {
        CalendarStripView(days: releaseCalendarDays, selectedDate: $store.selectedReleaseDate, countLabel: releaseCountLabel)
      }
    }
    .onChange(of: store.selectedReleaseDate) { _, date in
      store.selectedReleaseID = releases(on: date).first?.id
    }
  }

  @ViewBuilder
  private var selectedReleaseCard: some View {
    if let selectedRelease {
      VStack(alignment: .leading, spacing: 10) {
        Text("Selected release")
          .font(.headline)

        Text("\(selectedRelease.tag) \(selectedRelease.title)")
          .font(.title3.weight(.bold))

        Text(repository(for: selectedRelease.repoID)?.name ?? selectedRelease.repoID)
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Text(selectedRelease.notes)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .prbarSurface()
    } else {
      ActivityEmptyStateView(
        title: "No release selected",
        detail: selectedReleaseEmptyDetail,
        systemImage: "tag",
        identifier: "selected-release-empty-state"
      )
    }
  }

  private var releaseCadenceSummary: String {
    let count = releaseCalendarDays.reduce(0) { $0 + $1.count }
    return count == 1 ? "1 release" : "\(count) releases"
  }

  private var selectedReleaseDateLabel: String {
    shortDateLabel(for: store.selectedReleaseDate)
  }

  private var selectedReleaseEmptyDetail: String {
    if store.includedRepositories.isEmpty {
      return "Choose repos before looking for release details."
    }
    if store.isRefreshingActivity {
      return "Syncing included repositories. Release details will appear when refresh finishes."
    }
    return "Choose a day with releases or refresh GitHub activity."
  }

  private func releases(on date: Date) -> [ReleaseMoment] {
    let includedIDs = Set(store.includedRepositories.map(\.id))
    return store.releases.filter {
      includedIDs.contains($0.repoID) && CalendarDay.isSameDay($0.date, date)
    }
  }

  private func repository(for id: Repository.ID) -> Repository? {
    store.repositories.first { $0.id == id }
  }

  private func releaseCountLabel(for count: Int) -> String {
    count == 1 ? "release" : "releases"
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

private struct ActivitySummaryMetric: View {
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

      Text(label)
        .font(.caption.weight(.medium))
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .prbarSurface()
  }
}

private struct ActivitySectionHeader: View {
  var title: String
  var detail: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.title3.weight(.bold))
      Text(detail)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

private struct DailyPRChartDay: Identifiable {
  var day: CalendarDay
  var segments: [DailyPRChartSegment]

  var id: Date { day.date }
  var count: Int { day.count }
}

private struct DailyPRChartSegment: Identifiable {
  var repositoryID: Repository.ID
  var count: Int
  var color: Color

  var id: Repository.ID { repositoryID }
}

private struct DailyPRBarChart: View {
  var days: [DailyPRChartDay]

  private var maxCount: Int {
    max(days.map(\.count).max() ?? 1, 1)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Daily merges")
        .font(.headline)

      HStack(alignment: .bottom, spacing: 8) {
        ForEach(days) { day in
          VStack(spacing: 6) {
            VStack(spacing: 2) {
              if day.segments.isEmpty {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                  .fill(Color(.tertiarySystemFill))
                  .frame(height: 8)
              } else {
                ForEach(day.segments) { segment in
                  RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(segment.color.gradient)
                    .frame(height: max(8, CGFloat(segment.count) / CGFloat(maxCount) * 72))
                }
              }
            }
            .frame(height: 76, alignment: .bottom)
            .accessibilityLabel("\(day.count) merged pull requests on day \(day.day.dayNumber)")

            Text("\(day.day.dayNumber)")
              .font(.caption2)
              .foregroundStyle(.secondary)
              .monospacedDigit()
          }
          .frame(maxWidth: .infinity)
        }
      }
      .frame(height: 96)
    }
  }
}

#Preview {
  PRsView(store: .sample())
}
