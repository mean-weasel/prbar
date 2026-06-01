import SwiftUI

struct SettingsView: View {
  var store: PRBarStore

  var body: some View {
    let diagnostics = store.settingsDiagnostics

    Form {
      Section("GitHub") {
        LabeledContent("Account", value: diagnostics.account)
        LabeledContent("Auth", value: diagnostics.auth)
        LabeledContent("Data source", value: diagnostics.dataSource)
        LabeledContent("Included repos", value: diagnostics.includedRepositories)
        LabeledContent("Available repos", value: diagnostics.availableRepositories)
        NavigationLink("Manage included repos") {
          RepositorySetupView(store: store)
        }
      }

      Section("Status") {
        LabeledContent("Sync", value: diagnostics.sync)
        LabeledContent("Last refresh", value: diagnostics.lastRefresh)
        LabeledContent("Last attempt", value: diagnostics.lastAttempt)
        if let issueTitle = diagnostics.issueTitle {
          VStack(alignment: .leading, spacing: 4) {
            Text(issueTitle)
              .font(.subheadline.weight(.semibold))
            if let issueDetail = diagnostics.issueDetail {
              Text(issueDetail)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
          .padding(.vertical, 4)
        }
      }

      Section("Growth") {
        NavigationLink("PostHog") {
          PostHogSettingsView(snapshot: store.growthSnapshot)
        }
      }

      Section("About") {
        LabeledContent("Version", value: AppVersion.current.displayValue)
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
