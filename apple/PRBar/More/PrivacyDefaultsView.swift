import SwiftUI

struct PrivacyDefaultsView: View {
  @Bindable var store: PRBarStore

  var body: some View {
    Form {
      Section {
        Toggle("Show repos", isOn: $store.cardDraft.showRepos)
        Toggle("Show handle", isOn: $store.cardDraft.showHandle)
        Toggle("Exact counts", isOn: $store.cardDraft.exactCounts)
        Toggle("Show private labels", isOn: $store.cardDraft.showPrivateLabels)
      } footer: {
        Text("These defaults apply to new work-card exports.")
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
