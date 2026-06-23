import SwiftUI

struct PrivacyDefaultsView: View {
  @Bindable var store: PRBarStore

  var body: some View {
    Form {
      Section {
        Toggle("Show repos", isOn: $store.cardDraft.showRepos)
        Text(store.cardDraft.showRepos ? "More specific cards can name selected repositories." : "Safer cards hide repository names.")
          .font(.caption)
          .foregroundStyle(.secondary)
        Toggle("Show handle", isOn: $store.cardDraft.showHandle)
        Toggle("Exact counts", isOn: $store.cardDraft.exactCounts)
        Text(store.cardDraft.exactCounts ? "More specific cards show exact totals." : "Safer cards soften activity counts.")
          .font(.caption)
          .foregroundStyle(.secondary)
        Toggle("Show private labels", isOn: $store.cardDraft.showPrivateLabels)
      } footer: {
        Text("These defaults apply to work-card exports. Private repo names, exact counts, PR titles, release notes, and private labels can reveal sensitive work.")
      }
    }
    .navigationTitle("Privacy")
  }
}

#Preview {
  NavigationStack {
    PrivacyDefaultsView(store: .sample())
  }
}
