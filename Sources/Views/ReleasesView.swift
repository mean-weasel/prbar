import AppKit
import SwiftUI

struct ReleasesView: View {
  var releaseStore: ReleaseMomentStore
  var repositories: [RepositoryActivity]
  var onEditRepos: () -> Void
  var onShare: (ShareCardPayload) -> Void
  @State private var selectedReleaseID: String?
  @State private var copyMessage: String?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if visibleReleases.isEmpty {
        emptyState
      } else {
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
    VStack(spacing: 10) {
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
    .frame(maxWidth: .infinity)
    .padding(.vertical, 22)
    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
  }

  private var releaseList: some View {
    ScrollView {
      LazyVStack(spacing: 8) {
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
    .frame(maxHeight: 190)
  }

  private func releaseDetail(_ release: ReleaseMoment) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 2) {
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

      HStack {
        Button("Share Release Card") {
          onShare(
            .release(
              ShareCardBuilder.releasePayload(
                release: release,
                repository: repository(for: release)
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
    .padding(10)
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
      VStack(alignment: .leading, spacing: 5) {
        HStack {
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
      .padding(10)
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
