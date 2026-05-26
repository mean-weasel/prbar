import SwiftUI

struct RepositorySetupView: View {
  private var store: PRBarStore?
  private var fallbackRepositories: [Repository]
  private var title: String
  private var showsFinishButton: Bool
  @State private var searchText = ""

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
    .navigationTitle(title)
    .searchable(text: $searchText, prompt: "Search repos")
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
}

#Preview {
  NavigationStack {
    RepositorySetupView(repositories: SampleData.repositories)
  }
}
