import SwiftUI

struct ReleaseRowView: View {
  var release: ReleaseMoment
  var repository: Repository?

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("\(release.tag) \(release.title)")
        .font(.subheadline.weight(.semibold))

      HStack(spacing: 8) {
        Label(release.source.rawValue.capitalized, systemImage: release.source == .release ? "shippingbox" : "tag")

        if let repository {
          Text(repository.name)
        }
      }
      .font(.caption)
      .foregroundStyle(.secondary)

      Text(release.notes)
        .font(.caption)
        .foregroundStyle(.secondary)
        .lineLimit(2)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
  }
}

#Preview {
  ReleaseRowView(release: SampleData.releases[0], repository: SampleData.repositories[0])
    .padding()
}
