import SwiftUI

struct ActivitySyncStatusView: View {
  var isRefreshing: Bool
  var lastRefreshedAt: Date?
  var issue: AuthIssue?

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      statusIcon
        .font(.subheadline.weight(.semibold))
        .frame(width: 20, height: 20)

      VStack(alignment: .leading, spacing: 3) {
        Text(title)
          .font(.subheadline.weight(.semibold))
        Text(detail)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    .accessibilityIdentifier("activity-sync-status")
  }

  @ViewBuilder
  private var statusIcon: some View {
    if isRefreshing {
      ProgressView()
    } else if issue != nil {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.orange)
    } else {
      Image(systemName: "checkmark.circle.fill")
        .foregroundStyle(.green)
    }
  }

  private var title: String {
    if isRefreshing {
      return "Refreshing GitHub activity"
    }
    if issue != nil {
      return "Last refresh failed"
    }
    if lastRefreshedAt != nil {
      return "Last refreshed"
    }
    return "Not refreshed yet"
  }

  private var detail: String {
    if isRefreshing {
      return "Syncing included repositories from GitHub."
    }
    if let issue {
      return issue.message
    }
    if let lastRefreshedAt {
      return dateFormatter.string(from: lastRefreshedAt)
    }
    return "Pull to refresh or use the refresh button to sync included repos."
  }

  private var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = .current
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
  }
}

#Preview {
  VStack {
    ActivitySyncStatusView(isRefreshing: false, lastRefreshedAt: Date(), issue: nil)
    ActivitySyncStatusView(isRefreshing: true, lastRefreshedAt: nil, issue: nil)
    ActivitySyncStatusView(isRefreshing: false, lastRefreshedAt: nil, issue: AuthIssue(id: "issue", title: "Issue", message: "GitHub was unavailable."))
  }
  .padding()
}
