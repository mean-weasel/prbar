import SwiftUI

struct SettingsView: View {
  var store: PRBarStore

  var body: some View {
    Form {
      Section("GitHub") {
        LabeledContent("Account", value: "@neonwatty")
        LabeledContent("Data source", value: "Fixtures")
        LabeledContent("Included repos", value: "\(store.includedRepositories.count)")
      }

      Section("Status") {
        LabeledContent("Sync", value: "Ready")
        LabeledContent("Auth", value: "Demo")
        LabeledContent("Last update", value: "Sample data")
      }
    }
    .navigationTitle("Settings")
  }
}

#Preview {
  NavigationStack {
    SettingsView(store: .sample())
  }
}
