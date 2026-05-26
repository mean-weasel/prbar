import SwiftUI

struct PRsView: View {
  @Bindable var store: PRBarStore

  private var calendarDays: [CalendarDay] {
    CalendarDay.days(endingAt: SampleData.today, range: store.prRange).map { day in
      CalendarDay(date: day.date, count: pullRequests(on: day.date).count)
    }
  }

  private var selectedPullRequests: [PullRequest] {
    pullRequests(on: store.selectedPRDate)
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

          RangePickerView(selection: $store.prRange)

          calendar

          selectedDayMetric

          DailyPRBarChart(days: calendarDays)

          RepoDistributionView(rows: repoRows)

          recentPRs
        }
        .padding()
      }
      .navigationTitle("PRs")
      .navigationDestination(for: Repository.ID.self) { repositoryID in
        PRRepositoryDetailView(
          repository: repository(for: repositoryID),
          pullRequests: store.pullRequests.filter { $0.repoID == repositoryID }
        )
      }
    }
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
        RepositorySetupView(repositories: store.includedRepositories)
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

      ForEach(store.pullRequests.sorted { $0.mergedAt > $1.mergedAt }.prefix(5)) { pullRequest in
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

private struct DailyPRBarChart: View {
  var days: [CalendarDay]

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
            RoundedRectangle(cornerRadius: 4, style: .continuous)
              .fill(day.count > 0 ? PRBarTheme.accent : Color(.tertiarySystemFill))
              .frame(height: CGFloat(max(day.count, 1)) / CGFloat(maxCount) * 72)

            Text("\(day.dayNumber)")
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
