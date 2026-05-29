import SwiftUI

struct RepositorySetupView: View {
  private enum RepositoryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case selected = "Selected"
    case available = "Available"
    case blocked = "Blocked"

    var id: String { rawValue }
  }

  private var store: PRBarStore?
  private var fallbackRepositories: [Repository]
  private var title: String
  private var showsFinishButton: Bool
  @State private var searchText = ""
  @State private var filter: RepositoryFilter = .all

  init(store: PRBarStore, title: String = "Repos", showsFinishButton: Bool = false) {
    self.store = store
    self.fallbackRepositories = []
    self.title = title
    self.showsFinishButton = showsFinishButton
  }

  init(repositories: [Repository]) {
    self.store = nil
    self.fallbackRepositories = repositories
    self.title = "Repos"
    self.showsFinishButton = false
  }

  var body: some View {
    List {
      Section {
        Text("Included repos power PRs, Releases, and Cards.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      if let user = store?.githubConnection.user {
        Section {
          Label("@\(user.login)", systemImage: "person.crop.circle")
            .font(.subheadline)
        } header: {
          Text("GitHub")
        }
      }

      Section {
        VStack(alignment: .leading, spacing: 12) {
          HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
              .foregroundStyle(.secondary)
            TextField("Search repos", text: $searchText)
              .textInputAutocapitalization(.never)
              .autocorrectionDisabled()
              .accessibilityIdentifier("repo-search-field")
            if searchText.isEmpty == false {
              Button {
                searchText = ""
              } label: {
                Label("Clear repo search", systemImage: "xmark.circle.fill")
                  .labelStyle(.iconOnly)
              }
              .foregroundStyle(.secondary)
            }
          }
          .padding(10)
          .background(Color(.tertiarySystemFill))
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

          HStack {
            Label(selectionSummaryText, systemImage: "checkmark.circle")
            Spacer()
            Text("\(availableCount) available")
              .foregroundStyle(.secondary)
          }
          .font(.subheadline)

          if showsFinishButton && includedCount == 0 {
            Text("Select at least one repo to finish setup.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          Picker("Repo filter", selection: $filter) {
            ForEach(RepositoryFilter.allCases) { filter in
              Text(filter.rawValue).tag(filter)
            }
          }
          .pickerStyle(.segmented)
          .accessibilityIdentifier("repo-filter-picker")

          HStack(spacing: 10) {
            Button {
              setVisibleReadyRepositories(included: true)
            } label: {
              Label("Select visible", systemImage: "checkmark.circle")
            }
            .buttonStyle(.bordered)
            .disabled(store == nil || visibleReadyRepositories.isEmpty)

            Button {
              setVisibleReadyRepositories(included: false)
            } label: {
              Label("Clear visible", systemImage: "xmark.circle")
            }
            .buttonStyle(.bordered)
            .disabled(store == nil || visibleSelectedRepositories.isEmpty)
          }
          .font(.subheadline)
        }
      }

      if filteredRepositories.isEmpty {
        Section(filteredSectionTitle) {
          emptyState
        }
      } else {
        ForEach(groupedFilteredRepositories, id: \.owner) { group in
          Section("\(group.owner) repos") {
            ForEach(group.repositories) { repository in
              repositoryRow(repository)
            }
          }
        }
      }

      Section("Access") {
        HStack {
          Label("SSO protected repos", systemImage: "lock")
          Spacer()
          Text("Disabled")
            .foregroundStyle(.secondary)
        }
        .font(.subheadline)
      }

      if let store, store.isRefreshingActivity || store.activityRefreshIssue != nil || store.lastActivityRefreshAt != nil {
        Section("Sync") {
          ActivitySyncStatusView(
            isRefreshing: store.isRefreshingActivity,
            progress: store.activityRefreshProgress,
            lastRefreshedAt: store.lastActivityRefreshAt,
            lastRefreshAttemptAt: store.lastActivityRefreshAttemptAt,
            issue: store.activityRefreshIssue
          )
          .listRowInsets(EdgeInsets())
          .listRowBackground(Color.clear)
        }
      }

    }
    .navigationTitle(title)
    .safeAreaInset(edge: .bottom) {
      selectionSummaryBar
    }
    .toolbar {
      if showsFinishButton {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            store?.finishRepositorySetup()
          } label: {
            if store?.isRefreshingActivity == true {
              ProgressView()
            } else {
              Text("Finish setup")
            }
          }
          .buttonStyle(.borderedProminent)
          .disabled(store == nil || includedCount == 0 || store?.isRefreshingActivity == true)
        }
      }
    }
  }

  private var repositories: [Repository] {
    store?.repositories ?? fallbackRepositories
  }

  private var filteredRepositories: [Repository] {
    repositories.filter { repository in
      matchesSearch(repository) && matchesFilter(repository)
    }
  }

  private var includedCount: Int {
    repositories.filter(\.included).count
  }

  private var visibleReadyRepositories: [Repository] {
    filteredRepositories.filter { $0.access == .ready }
  }

  private var visibleSelectedRepositories: [Repository] {
    visibleReadyRepositories.filter(\.included)
  }

  private var availableCount: Int {
    repositories.filter { $0.access == .ready }.count
  }

  private var selectionSummaryText: String {
    "\(includedCount) of \(repositories.count) selected"
  }

  private var groupedFilteredRepositories: [(owner: String, repositories: [Repository])] {
    Dictionary(grouping: filteredRepositories, by: \.owner)
      .map { owner, repositories in
        (
          owner: owner,
          repositories: repositories.sorted {
            if $0.recommended != $1.recommended {
              return $0.recommended && !$1.recommended
            }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
          }
        )
      }
      .sorted { lhs, rhs in
        lhs.owner.localizedCaseInsensitiveCompare(rhs.owner) == .orderedAscending
      }
  }

  private var filteredSectionTitle: String {
    if searchText.isEmpty {
      return filter.rawValue
    }
    return "Results"
  }

  private var emptyState: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Repo not showing up?")
        .font(.subheadline.weight(.semibold))

      VStack(alignment: .leading, spacing: 4) {
        Label("Install PRBar in the GitHub organization.", systemImage: "building.2")
        Label("Authorize SSO for protected organizations.", systemImage: "lock.shield")
        Label("Check your repository permissions.", systemImage: "person.badge.key")
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.vertical, 8)
    .accessibilityIdentifier("repo-empty-state")
  }

  private func matchesSearch(_ repository: Repository) -> Bool {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard query.isEmpty == false else {
      return true
    }

    return repository.name.localizedCaseInsensitiveContains(query) ||
      repository.owner.localizedCaseInsensitiveContains(query) ||
      repository.fullName.localizedCaseInsensitiveContains(query) ||
      repository.id.localizedCaseInsensitiveContains(query) ||
      repository.reason.localizedCaseInsensitiveContains(query)
  }

  private func matchesFilter(_ repository: Repository) -> Bool {
    switch filter {
    case .all:
      return true
    case .selected:
      return repository.included
    case .available:
      return repository.access == .ready && repository.included == false
    case .blocked:
      return repository.access != .ready
    }
  }

  private func repositoryRow(_ repository: Repository) -> some View {
    Toggle(isOn: includedBinding(for: repository)) {
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 8) {
          Text(repository.name)
            .font(.subheadline.weight(.semibold))

          if repository.recommended {
            Text("Recommended")
              .font(.caption2.weight(.semibold))
              .foregroundStyle(PRBarTheme.accent)
          }
        }

        Text(repository.fullName)
          .font(.caption)
          .foregroundStyle(.secondary)

        Text(repository.reason)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
    .accessibilityLabel("Include \(repository.name)")
    .disabled(repository.access == .sso || store == nil)
  }

  private func includedBinding(for repository: Repository) -> Binding<Bool> {
    Binding(
      get: {
        store?.repositories.first(where: { $0.id == repository.id })?.included ?? repository.included
      },
      set: { isIncluded in
        store?.setRepositoryIncluded(repository.id, included: isIncluded)
      }
    )
  }

  private func setVisibleReadyRepositories(included: Bool) {
    guard let store else {
      return
    }

    let visibleIDs = Set(visibleReadyRepositories.map(\.id))
    store.setRepositoriesIncluded(visibleIDs, included: included)
  }

  private var selectionSummaryBar: some View {
    HStack(spacing: 10) {
      Label(selectionSummaryText, systemImage: "checkmark.circle")
        .font(.subheadline.weight(.medium))
      Spacer()
      Text("\(availableCount) available")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .background(.bar)
  }
}

#Preview {
  NavigationStack {
    RepositorySetupView(repositories: SampleData.repositories)
  }
}
