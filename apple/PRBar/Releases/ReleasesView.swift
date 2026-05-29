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
          header

          syncStatus

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
        Text("Shipping moments")
          .font(.largeTitle.weight(.bold))
        Text("Tagged releases from included repositories")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Spacer()

      NavigationLink {
        RepositorySetupView(store: store)
      } label: {
        Label("\(store.includedRepositories.count) repos", systemImage: "folder")
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
        detail: "Choose a day with releases or refresh GitHub activity.",
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
          title: "No releases or tags",
          detail: "Refresh GitHub activity or include repos that publish releases.",
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
