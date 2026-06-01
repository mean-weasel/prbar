import SwiftUI

struct PostHogSettingsView: View {
  var snapshot: GrowthDashboardSnapshot
  var environment: [String: String] = ProcessInfo.processInfo.environment

  private var diagnostics: PostHogConnectionDiagnostics {
    PostHogConnectionDiagnostics.current(environment: environment, snapshot: snapshot)
  }

  var body: some View {
    Form {
      Section("Connection") {
        LabeledContent("Status", value: diagnostics.status)

        if let issue = diagnostics.issue {
          VStack(alignment: .leading, spacing: 4) {
            Text("Issue")
              .font(.subheadline.weight(.semibold))
            Text(issue)
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .padding(.vertical, 4)
        }
      }

      Section("Configuration") {
        LabeledContent("Live config", value: diagnostics.configuration)
        LabeledContent("Host", value: diagnostics.host)
        LabeledContent("Project ID", value: diagnostics.projectID)
        LabeledContent("Personal API key", value: diagnostics.personalAPIKey)
      }
    }
    .navigationTitle("PostHog")
  }
}

#Preview {
  NavigationStack {
    PostHogSettingsView(snapshot: SampleData.growthDashboard)
  }
}
