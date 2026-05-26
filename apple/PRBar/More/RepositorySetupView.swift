import SwiftUI

struct RepositorySetupView: View {
  var repositories: [Repository]

  var body: some View {
    List(repositories) { repository in
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(repository.name)
            .font(.subheadline.weight(.semibold))

          Spacer()

          Text(repository.included ? "Included" : "Excluded")
            .font(.caption.weight(.semibold))
            .foregroundStyle(repository.included ? PRBarTheme.accent : .secondary)
        }

        Text(repository.owner)
          .font(.caption)
          .foregroundStyle(.secondary)

        Text(repository.reason)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding(.vertical, 4)
    }
    .navigationTitle("Repos")
  }
}

#Preview {
  NavigationStack {
    RepositorySetupView(repositories: SampleData.repositories)
  }
}
