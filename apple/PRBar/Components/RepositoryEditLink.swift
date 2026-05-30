import SwiftUI

struct RepositoryEditLink: View {
  var store: PRBarStore
  var systemImage: String = "folder.badge.gearshape"

  var body: some View {
    NavigationLink {
      RepositorySetupView(store: store)
    } label: {
      HStack(spacing: 8) {
        Image(systemName: systemImage)
        Text("Repos")
          .font(.subheadline.weight(.semibold))
        Text("\(store.includedRepositories.count)")
          .font(.caption.weight(.bold))
          .monospacedDigit()
          .foregroundStyle(.white)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(PRBarTheme.accent)
          .clipShape(Capsule())
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 8)
      .background(Color(.secondarySystemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      .fixedSize(horizontal: true, vertical: false)
    }
    .accessibilityLabel("Edit repos")
  }
}

#Preview {
  NavigationStack {
    RepositoryEditLink(store: .sample())
      .padding()
  }
}
