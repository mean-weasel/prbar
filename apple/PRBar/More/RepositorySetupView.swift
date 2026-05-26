import SwiftUI

struct RepositorySetupView: View {
  private var store: PRBarStore?
  private var fallbackRepositories: [Repository]
  @State private var searchText = ""

  init(store: PRBarStore) {
    self.store = store
    self.fallbackRepositories = []
  }

  init(repositories: [Repository]) {
    self.store = nil
    self.fallbackRepositories = repositories
  }

  var body: some View {
    List {
      Section {
        Text("Included repos power PRs, Releases, and Cards.")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Section("Included") {
        ForEach(filteredRepositories) { repository in
          repositoryRow(repository)
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
    .navigationTitle("Repos")
    .searchable(text: $searchText, prompt: "Search repos")
  }

  private var repositories: [Repository] {
    store?.repositories ?? fallbackRepositories
  }

  private var filteredRepositories: [Repository] {
    guard !searchText.isEmpty else { return repositories }
    return repositories.filter {
      $0.name.localizedCaseInsensitiveContains(searchText) ||
        $0.owner.localizedCaseInsensitiveContains(searchText)
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
}

#Preview {
  NavigationStack {
    RepositorySetupView(repositories: SampleData.repositories)
  }
}
