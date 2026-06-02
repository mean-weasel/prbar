import SwiftUI

struct ActivitySyncStatusView: View {
  var isRefreshing: Bool
  var context: ActivityRefreshContext?
  var progress: ActivityRefreshProgress?
  var lastRefreshedAt: Date?
  var lastRefreshAttemptAt: Date?
  var issue: AuthIssue?
  var repositoryIssues: [ActivityRepositoryIssue]

  init(
    isRefreshing: Bool,
    context: ActivityRefreshContext? = nil,
    progress: ActivityRefreshProgress? = nil,
    lastRefreshedAt: Date?,
    lastRefreshAttemptAt: Date?,
    issue: AuthIssue?,
    repositoryIssues: [ActivityRepositoryIssue] = []
  ) {
    self.isRefreshing = isRefreshing
    self.context = context
    self.progress = progress
    self.lastRefreshedAt = lastRefreshedAt
    self.lastRefreshAttemptAt = lastRefreshAttemptAt
    self.issue = issue
    self.repositoryIssues = repositoryIssues
  }

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
    } else if repositoryIssues.isEmpty == false {
      Image(systemName: "exclamationmark.circle.fill")
        .foregroundStyle(.orange)
    } else if issue != nil && lastRefreshedAt != nil {
      Image(systemName: "clock.badge.exclamationmark.fill")
        .foregroundStyle(.orange)
    } else if issue != nil {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.orange)
    } else if lastRefreshedAt == nil {
      Image(systemName: "arrow.triangle.2.circlepath")
        .foregroundStyle(PRBarTheme.accent)
    } else {
      Image(systemName: "checkmark.circle.fill")
        .foregroundStyle(.green)
    }
  }

  private var title: String {
    if isRefreshing {
      if case .setup = context {
        return "Syncing selected repos"
      }
      return "Refreshing GitHub activity"
    }
    if repositoryIssues.isEmpty == false {
      return "Partial GitHub sync"
    }
    if issue != nil && lastRefreshedAt != nil {
      return "Showing cached GitHub data"
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
      let setupPrefix: String
      if case let .setup(repositoryCount) = context {
        setupPrefix = "Fetching PRs and releases from \(repositoryLabel(repositoryCount)). "
      } else {
        setupPrefix = ""
      }

      guard let progress else {
        return "\(setupPrefix)Syncing included repositories from GitHub."
      }

      let repoText: String
      if let currentRepositoryName = progress.currentRepositoryName {
        repoText = "Syncing \(progress.completedRepositories + 1) of \(progress.totalRepositories): \(currentRepositoryName)."
      } else {
        repoText = "Synced \(progress.completedRepositories) of \(progress.totalRepositories) repositories."
      }
      return "\(setupPrefix)\(repoText) Found \(progress.pullRequestCount) PRs and \(progress.releaseCount) releases so far."
    }
    if repositoryIssues.isEmpty == false {
      let issueCount = repositoryIssues.count
      let issueText = issueCount == 1 ? "1 repository needs attention" : "\(issueCount) repositories need attention"
      guard let firstIssue = repositoryIssues.first else {
        return "Synced available data. \(issueText)."
      }
      return "Synced available data. \(issueText): \(firstIssue.message)"
    }
    if let issue {
      if let lastRefreshedAt {
        return "\(attemptLabel) \(issue.message) Showing cached data from \(dateFormatter.string(from: lastRefreshedAt))."
      }
      return issue.message
    }
    if let lastRefreshedAt {
      return "Synced selected repositories \(dateFormatter.string(from: lastRefreshedAt))."
    }
    return "Pull to refresh or use the refresh button to sync included repositories."
  }

  private var attemptLabel: String {
    guard let lastRefreshAttemptAt else {
      return "Retry failed."
    }
    return "Retry failed \(dateFormatter.string(from: lastRefreshAttemptAt))."
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

  private func repositoryLabel(_ count: Int) -> String {
    count == 1 ? "1 selected repo" : "\(count) selected repos"
  }
}

#Preview {
  VStack {
    ActivitySyncStatusView(isRefreshing: false, lastRefreshedAt: Date(), lastRefreshAttemptAt: Date(), issue: nil)
    ActivitySyncStatusView(isRefreshing: true, lastRefreshedAt: nil, lastRefreshAttemptAt: Date(), issue: nil)
    ActivitySyncStatusView(isRefreshing: false, lastRefreshedAt: Date(), lastRefreshAttemptAt: Date(), issue: AuthIssue(id: "issue", title: "Issue", message: "GitHub was unavailable."))
    ActivitySyncStatusView(
      isRefreshing: false,
      lastRefreshedAt: Date(),
      lastRefreshAttemptAt: Date(),
      issue: nil,
      repositoryIssues: [
        ActivityRepositoryIssue(repositoryID: "mean-weasel/private-api", repositoryFullName: "mean-weasel/private-api", title: "Repository needs attention", message: "Authorize SSO for mean-weasel/private-api, then refresh again.")
      ]
    )
  }
  .padding()
}
