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
    .prbarSurface(
      isSelected: isSelected,
      strokeColor: isSelected ? PRBarTheme.accent : .clear
    )
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(metric.provider.displayName), \(metric.title)")
    .accessibilityValue(accessibilityValue)
  }

  private var accessibilityValue: String {
    if let delta = metric.delta {
      return "\(metric.formattedValue), \(delta.formattedValue)"
    }
    return metric.formattedValue
  }

  private func deltaColor(_ direction: GrowthDelta.Direction) -> Color {
    switch direction {
    case .positive: .green
    case .negative: .orange
    case .neutral: .secondary
    }
  }
}
