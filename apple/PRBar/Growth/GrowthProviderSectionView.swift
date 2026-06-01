import SwiftUI

struct GrowthProviderSectionView: View {
  var provider: GrowthProviderKind
  var rows: [GrowthListRow]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(provider.displayName)
        .font(.headline)

      ForEach(rows) { row in
        HStack(alignment: .firstTextBaseline, spacing: 12) {
          VStack(alignment: .leading, spacing: 3) {
            Text(row.title)
              .font(.subheadline.weight(.semibold))
            Text(row.detail)
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          Spacer()

          Text(row.value)
            .font(.subheadline.weight(.bold))
            .monospacedDigit()
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      }
    }
  }
}
