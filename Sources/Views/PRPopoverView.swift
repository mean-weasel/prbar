import SwiftUI

struct PRPopoverView: View {
  var store: PRActivityStore

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      header
      summary
      repositoryList
      footer
    }
    .padding(18)
  }

  private var header: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("PR Activity")
          .font(.headline)
        Text(store.window.rawValue)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Button("Refresh") {}
        .buttonStyle(.bordered)
    }
  }

  private var summary: some View {
    HStack(spacing: 12) {
      MetricTile(value: "\(store.totalPullRequests)", label: "merged")
      MetricTile(value: "\(store.activeRepositoryCount)", label: "repos")
      MetricTile(value: "\(store.window.dayCount)", label: "days")
    }
  }

  private var repositoryList: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Repositories")
        .font(.caption)
        .foregroundStyle(.secondary)
      ForEach(store.repositories) { repository in
        RepositoryActivityRow(repository: repository)
      }
    }
  }

  private var footer: some View {
    Text("Last refreshed \(store.refreshedAt.formatted(date: .omitted, time: .shortened))")
      .font(.caption2)
      .foregroundStyle(.tertiary)
  }
}

private struct MetricTile: View {
  var value: String
  var label: String

  var body: some View {
    VStack(spacing: 2) {
      Text(value)
        .font(.title3.monospacedDigit().weight(.semibold))
      Text(label)
        .font(.caption2)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 10)
    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
  }
}

private struct RepositoryActivityRow: View {
  var repository: RepositoryActivity

  var body: some View {
    HStack(spacing: 10) {
      RoundedRectangle(cornerRadius: 3)
        .fill(Color(hex: repository.colorHex))
        .frame(width: 10, height: 24)
      VStack(alignment: .leading, spacing: 2) {
        Text(repository.name)
          .font(.subheadline.weight(.medium))
        Text(repository.owner)
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Text("\(repository.total)")
        .font(.subheadline.monospacedDigit().weight(.semibold))
    }
  }
}
