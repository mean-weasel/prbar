import SwiftUI

struct ReleasesView: View {
  @Bindable var store: PRBarStore

  private var calendarDays: [CalendarDay] {
    CalendarDay.days(endingAt: store.activityAnchorDate, range: store.releaseRange).map { day in
      CalendarDay(date: day.date, count: releases(on: day.date).count)
    }
  }

  private var selectedRelease: ReleaseMoment? {
    releases(on: store.selectedReleaseDate).first
      ?? store.releases.first { $0.id == store.selectedReleaseID }
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

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          if store.isRefreshingActivity {
            syncStatus
          }

          header

          if store.isRefreshingActivity == false {
            syncStatus
          }

          RangePickerView(selection: $store.releaseRange)

          calendar

          selectedReleaseCard

          releaseRows
        }
        .padding()
      }
      .refreshable {
        await store.refreshActivity()
      }
      .navigationTitle("Releases")
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
    }
  }

  @ViewBuilder
  private var syncStatus: some View {
    ActivitySyncStatusView(
      isRefreshing: store.isRefreshingActivity,
      context: store.activityRefreshContext,
      progress: store.activityRefreshProgress,
      lastRefreshedAt: store.lastActivityRefreshAt,
      lastRefreshAttemptAt: store.lastActivityRefreshAttemptAt,
      issue: store.activityRefreshIssue,
      repositoryIssues: store.activityRepositoryIssues
    )
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Text("Shipping moments")
          .font(.largeTitle.weight(.bold))
        Text("Tagged releases from included repositories")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      RepositoryEditLink(store: store, systemImage: "folder")
    }
  }

  @ViewBuilder
  private var calendar: some View {
    Group {
      if store.releaseRange == .month {
        MonthHeatMapView(days: calendarDays, selectedDate: $store.selectedReleaseDate, countLabel: releaseCountLabel)
      } else {
        CalendarStripView(days: calendarDays, selectedDate: $store.selectedReleaseDate, countLabel: releaseCountLabel)
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
      .padding(14)
      .background(Color(.secondarySystemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    } else {
      ActivityEmptyStateView(
        title: "No release selected",
        detail: selectedReleaseEmptyDetail,
        systemImage: "tag",
        identifier: "selected-release-empty-state"
      )
    }
  }

  @ViewBuilder
  private var releaseRows: some View {
    VStack(alignment: .leading, spacing: 16) {
      if groupedReleases.isEmpty {
        ActivityEmptyStateView(
          title: releaseRowsEmptyTitle,
          detail: releaseRowsEmptyDetail,
          systemImage: "shippingbox",
          identifier: "releases-empty-state"
        )
      } else {
        ForEach(groupedReleases, id: \.date) { group in
          VStack(alignment: .leading, spacing: 10) {
            Text(longDateLabel(for: group.date))
              .font(.headline)

            ForEach(group.releases) { release in
              ReleaseRowView(release: release, repository: repository(for: release.repoID))
            }
          }
        }
      }
    }
  }

  private func releases(on date: Date) -> [ReleaseMoment] {
    let includedIDs = Set(store.includedRepositories.map(\.id))
    return store.releases.filter {
      includedIDs.contains($0.repoID) && CalendarDay.isSameDay($0.date, date)
    }
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

  private func repository(for id: Repository.ID) -> Repository? {
    store.repositories.first { $0.id == id }
  }

  private func longDateLabel(for date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "MMMM d"
    return formatter.string(from: date)
  }

  private func releaseCountLabel(for count: Int) -> String {
    count == 1 ? "release" : "releases"
  }

  private var fixtureCalendar: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }
}

#Preview {
  ReleasesView(store: .sample())
}
