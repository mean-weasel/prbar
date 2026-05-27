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
            Label("\(includedCount) selected", systemImage: "checkmark.circle")
            Spacer()
            Text("\(repositories.count) total")
              .foregroundStyle(.secondary)
          }
          .font(.subheadline)

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

      Section(filteredSectionTitle) {
        if filteredRepositories.isEmpty {
          emptyState
        } else {
          ForEach(filteredRepositories) { repository in
            repositoryRow(repository)
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

    }
    .navigationTitle(title)
    .toolbar {
      if showsFinishButton {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Finish setup") {
            store?.finishRepositorySetup()
          }
          .buttonStyle(.borderedProminent)
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

  private var filteredSectionTitle: String {
    if searchText.isEmpty {
      return filter.rawValue
    }
    return "Results"
  }

  private var emptyState: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("No repos found")
        .font(.subheadline.weight(.semibold))
      Text("Try another search or filter.")
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

        Text(repository.owner)
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
        guard let index = store?.repositories.firstIndex(where: { $0.id == repository.id }) else {
          return
        }
        store?.repositories[index].included = isIncluded
      }
    )
  }

  private func setVisibleReadyRepositories(included: Bool) {
    guard let store else {
      return
    }

    let visibleIDs = Set(visibleReadyRepositories.map(\.id))
    for index in store.repositories.indices where visibleIDs.contains(store.repositories[index].id) {
      store.repositories[index].included = included
    }
  }
}

#Preview {
  NavigationStack {
    RepositorySetupView(repositories: SampleData.repositories)
  }
}
