import AppKit
import SwiftUI

struct ReleasesView: View {
  var releaseStore: ReleaseMomentStore
  var refreshState: ReleaseRefreshState = .idle
  var repositories: [RepositoryActivity]
  var revealingPrivateNamesInShare = false
  var onEditRepos: () -> Void
  var onShare: (ShareCardPayload) -> Void
  @State private var selectedReleaseID: String?
  @State private var copyMessage: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      if visibleReleases.isEmpty {
        emptyState
      } else {
        statusBanner
        releaseList
        if let selectedRelease {
          releaseDetail(selectedRelease)
        }
      }
      if let copyMessage {
        Text(copyMessage)
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }
    }
  }

  private var visibleReleases: [ReleaseMoment] {
    releaseStore.visibleReleases(for: repositories)
  }

  private var selectedRelease: ReleaseMoment? {
    let releases = visibleReleases
    guard releases.isEmpty == false else {
      return nil
    }
    if let selectedReleaseID,
      let selected = releases.first(where: { $0.id == selectedReleaseID })
    {
      return selected
    }
    return releases.first
  }

  private var emptyState: some View {
    VStack(spacing: 12) {
      switch refreshState {
      case .loading:
        ProgressView()
          .controlSize(.small)
        Text("Loading releases")
          .font(.subheadline.weight(.semibold))
        Text("Checking GitHub Releases and tags for included repositories.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      case .failed(let message):
        Image(systemName: "exclamationmark.triangle")
          .font(.title2)
          .foregroundStyle(.orange)
        Text("Release notes unavailable")
          .font(.subheadline.weight(.semibold))
        Text(message)
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
      case .idle:
        Image(systemName: "shippingbox")
          .font(.title2)
          .foregroundStyle(.secondary)
        Text("No releases in included repositories")
          .font(.subheadline.weight(.semibold))
        Text("Include more repositories to see GitHub Releases and tagged versions.")
          .font(.caption)
          .foregroundStyle(.secondary)
          .multilineTextAlignment(.center)
        Button("Edit Repos", action: onEditRepos)
          .buttonStyle(.bordered)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 30)
    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
  }

  @ViewBuilder
  private var statusBanner: some View {
    switch refreshState {
    case .loading:
      HStack(spacing: 8) {
        ProgressView()
          .controlSize(.small)
        Text("Refreshing release notes")
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    case .failed(let message):
      Label(message, systemImage: "exclamationmark.triangle")
        .font(.caption)
        .foregroundStyle(.orange)
    case .idle:
      EmptyView()
    }
  }

  private var releaseList: some View {
    ScrollView {
      LazyVStack(spacing: 14) {
        ForEach(visibleReleases) { release in
          ReleaseMomentRow(
            release: release,
            repository: repository(for: release),
            isSelected: selectedRelease?.id == release.id
          ) {
            selectedReleaseID = release.id
            copyMessage = nil
          }
        }
      }
    }
    .frame(maxHeight: 260)
  }

  private func releaseDetail(_ release: ReleaseMoment) -> some View {
    VStack(alignment: .leading, spacing: 18) {
      HStack(alignment: .firstTextBaseline, spacing: 16) {
        VStack(alignment: .leading, spacing: 4) {
          Text(release.source.notesTitle)
            .font(.caption2.weight(.bold))
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
          Text("\(release.tag) \(release.title)")
            .font(.subheadline.weight(.semibold))
        }
        Spacer()
        ReleaseBadge(source: release.source)
      }

      Text(release.notes)
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      HStack(spacing: 10) {
        Button("Share Release Card") {
          onShare(
            .release(
              ShareCardBuilder.releasePayload(
                release: release,
                repository: repository(for: release),
                revealingPrivateNames: revealingPrivateNamesInShare
              )
            )
          )
        }
        .buttonStyle(.borderedProminent)

        Button("Copy Notes") {
          NSPasteboard.general.clearContents()
          NSPasteboard.general.setString(release.notes, forType: .string)
          copyMessage = "Release notes copied."
        }
        .buttonStyle(.bordered)

        if let url = release.url {
          Link("Open on GitHub", destination: url)
            .font(.caption)
        }
      }
    }
    .padding(18)
    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
  }

  private func repository(for release: ReleaseMoment) -> RepositoryActivity? {
    repositories.first { $0.id == release.repositoryID }
  }
}

private struct ReleaseMomentRow: View {
  var release: ReleaseMoment
  var repository: RepositoryActivity?
  var isSelected: Bool
  var onSelect: () -> Void

  var body: some View {
    Button(action: onSelect) {
      VStack(alignment: .leading, spacing: 9) {
        HStack(spacing: 10) {
          Text("\(release.tag) \(release.title)")
            .font(.caption.weight(.semibold))
            .lineLimit(1)
          Spacer()
          ReleaseBadge(source: release.source)
        }
        Text(summaryText)
          .font(.caption2)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
      .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .buttonStyle(.plain)
    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
  }

  private var summaryText: String {
    let repositoryName = repository?.shareDisplayName ?? "Selected repo"
    let releaseDate = release.date.formatted(date: .abbreviated, time: .omitted)
    return "\(repositoryName) · \(releaseDate) · \(release.notes)"
  }
}

private struct ReleaseBadge: View {
  var source: ReleaseMoment.Source

  var body: some View {
    Text(source.badgeText)
      .font(.caption2.weight(.heavy))
      .padding(.horizontal, 6)
      .padding(.vertical, 2)
      .background(
        source == .tag ? Color.orange.opacity(0.16) : Color.cyan.opacity(0.16),
        in: Capsule()
      )
      .foregroundStyle(source == .tag ? .orange : .cyan)
  }
}
