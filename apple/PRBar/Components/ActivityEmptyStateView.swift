import SwiftUI

struct ActivityEmptyStateView: View {
  var title: String
  var detail: String
  var systemImage: String
  var identifier: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label(title, systemImage: systemImage)
        .font(.subheadline.weight(.semibold))
      Text(detail)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    .accessibilityIdentifier(identifier)
  }
}

#Preview {
  ActivityEmptyStateView(
    title: "No merged PRs",
    detail: "Refresh GitHub activity or include more repositories.",
    systemImage: "arrow.triangle.pull",
    identifier: "preview-empty"
  )
  .padding()
}
