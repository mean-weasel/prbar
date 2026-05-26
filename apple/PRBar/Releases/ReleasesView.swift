import SwiftUI

struct ReleasesView: View {
  @Bindable var store: PRBarStore

  private var calendarDays: [CalendarDay] {
    CalendarDay.days(endingAt: SampleData.today, range: store.releaseRange).map { day in
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

          RangePickerView(selection: $store.releaseRange)

          calendar

          selectedReleaseCard

          releaseRows
        }
        .padding()
      }
      .navigationTitle("Releases")
    }
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
        RepositorySetupView(repositories: store.includedRepositories)
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
    }
  }

  private var releaseRows: some View {
    VStack(alignment: .leading, spacing: 16) {
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
