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

  private var includedPullRequests: [PullRequest] {
    let includedIDs = Set(store.includedRepositories.map(\.id))
    return store.pullRequests
      .filter { includedIDs.contains($0.repoID) }
      .sorted { $0.mergedAt > $1.mergedAt }
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

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          header

          syncStatus

          RangePickerView(selection: $store.prRange)

          calendar

          selectedDayMetric

          DailyPRBarChart(days: chartDays)

          RepoDistributionView(rows: repoRows)

          recentPRs
        }
        .padding()
      }
      .refreshable {
        await store.refreshActivity()
      }
      .navigationTitle("PRs")
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
          pullRequests: store.pullRequests.filter { $0.repoID == repositoryID }
        )
      }
    }
  }

  private var syncStatus: some View {
    ActivitySyncStatusView(
      isRefreshing: store.isRefreshingActivity,
      progress: store.activityRefreshProgress,
      lastRefreshedAt: store.lastActivityRefreshAt,
      lastRefreshAttemptAt: store.lastActivityRefreshAttemptAt,
      issue: store.activityRefreshIssue,
      repositoryIssues: store.activityRepositoryIssues
    )
  }

  private var header: some View {
    HStack(alignment: .firstTextBaseline) {
      VStack(alignment: .leading, spacing: 6) {
        Text("Shipping rhythm")
          .font(.largeTitle.weight(.bold))
        Text("Merged work across included repositories")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Spacer()

      NavigationLink {
        RepositorySetupView(store: store)
      } label: {
        Label("\(store.includedRepositories.count) repos", systemImage: "folder.badge.gearshape")
          .labelStyle(.iconOnly)
          .font(.title3)
          .padding(10)
          .background(Color(.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      }
      .accessibilityLabel("\(store.includedRepositories.count) repositories")
    }
  }

  @ViewBuilder
  private var calendar: some View {
    if store.prRange == .month {
      MonthHeatMapView(days: calendarDays, selectedDate: $store.selectedPRDate, countLabel: pullRequestCountLabel)
    } else {
      CalendarStripView(days: calendarDays, selectedDate: $store.selectedPRDate, countLabel: pullRequestCountLabel)
    }
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
    .padding(14)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }

  private var recentPRs: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Recent PRs")
        .font(.headline)

      if includedPullRequests.isEmpty {
        ActivityEmptyStateView(
          title: "No merged PRs",
          detail: "Refresh GitHub activity or include more repositories.",
          systemImage: "arrow.triangle.pull",
          identifier: "prs-empty-state"
        )
      } else {
        ForEach(includedPullRequests.prefix(5)) { pullRequest in
          VStack(alignment: .leading, spacing: 4) {
            Text("#\(pullRequest.number) \(pullRequest.title)")
              .font(.subheadline.weight(.semibold))
            Text(repository(for: pullRequest.repoID)?.name ?? pullRequest.repoID)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(12)
          .background(Color(.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
      }
    }
  }

  private func pullRequests(on date: Date) -> [PullRequest] {
    let includedIDs = Set(store.includedRepositories.map(\.id))
    return store.pullRequests.filter {
      includedIDs.contains($0.repoID) && CalendarDay.isSameDay($0.mergedAt, date)
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

  private func pullRequestCountLabel(for count: Int) -> String {
    count == 1 ? "pull request" : "pull requests"
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

private struct PRRepositoryDetailView: View {
  var repository: Repository?
  var pullRequests: [PullRequest]

  var body: some View {
    List {
      Section(repository?.name ?? "Repository") {
        ForEach(pullRequests.sorted { $0.mergedAt > $1.mergedAt }) { pullRequest in
          VStack(alignment: .leading, spacing: 4) {
            Text("#\(pullRequest.number) \(pullRequest.title)")
              .font(.subheadline.weight(.semibold))
            Text("Merged")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .navigationTitle(repository?.name ?? "Repository")
  }
}

#Preview {
  PRsView(store: .sample())
}
