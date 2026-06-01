import SwiftUI

struct GrowthMetricTileView: View {
  var metric: GrowthMetric
  var isSelected: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(metric.provider.displayName)
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
        Spacer()
        if let delta = metric.delta {
          Text(delta.formattedValue)
            .font(.caption.weight(.bold))
            .foregroundStyle(deltaColor(delta.direction))
        }
      }

      Text(metric.formattedValue)
        .font(.title2.weight(.bold))
        .monospacedDigit()

      Text(metric.title)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .lineLimit(2)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(isSelected ? PRBarTheme.accent.opacity(0.12) : Color(.secondarySystemBackground))
    .overlay(
      RoundedRectangle(cornerRadius: 8, style: .continuous)
        .stroke(isSelected ? PRBarTheme.accent : Color.clear, lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    .accessibilityElement(children: .combine)
  }

  private func deltaColor(_ direction: GrowthDelta.Direction) -> Color {
    switch direction {
    case .positive: .green
    case .negative: .orange
    case .neutral: .secondary
    }
  }
}
