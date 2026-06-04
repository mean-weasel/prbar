import SwiftUI

struct GrowthTrendChartView: View {
  var metric: GrowthMetric
  var range: ActivityRange
  var anchorDate: Date
  private let chartHeight: CGFloat = 128

  private var points: [GrowthMetricPoint] {
    metric.normalizedSeries(endingAt: anchorDate, range: range)
  }

  private var axisScale: ChartAxisScale {
    ChartAxisScale(values: points.map(\.value))
  }

  private var barWidth: CGFloat {
    range == .month ? 10 : 26
  }

  private var chartSpacing: CGFloat {
    range == .month ? 4 : 8
  }

  private var xAxisTitle: String? {
    normalizedAxisTitle(metric.chartMetadata?.xAxisLabel)
  }

  private var yAxisTitle: String? {
    normalizedAxisTitle(metric.chartMetadata?.yAxisLabel)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(metric.title)
        .font(.headline)

      if let yAxisTitle {
        Text(yAxisTitle)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.secondary)
          .lineLimit(2)
          .accessibilityIdentifier("growth-y-axis-title")
      }

      HStack(alignment: .top, spacing: 8) {
        VStack(alignment: .trailing, spacing: 0) {
          ForEach(Array(axisScale.ticks.enumerated()), id: \.offset) { index, tick in
            Text(axisLabel(tick))
              .font(.caption2)
              .monospacedDigit()
              .foregroundStyle(.secondary)
              .frame(maxHeight: .infinity, alignment: axisTickAlignment(index))
          }
        }
        .frame(width: 42, height: chartHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Y-axis")
        .accessibilityValue("\(axisLabel(axisScale.minimum)) to \(axisLabel(axisScale.maximum))")
        .accessibilityIdentifier("growth-y-axis")

        ScrollView(.horizontal) {
          VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .bottomLeading) {
              VStack(spacing: 0) {
                ForEach(Array(axisScale.ticks.enumerated()), id: \.offset) { index, _ in
                  Rectangle()
                    .fill(Color(.separator).opacity(index == axisScale.ticks.count - 1 ? 0.45 : 0.2))
                    .frame(height: 1)
                  if index < axisScale.ticks.count - 1 {
                    Spacer(minLength: 0)
                  }
                }
              }

              HStack(alignment: .bottom, spacing: chartSpacing) {
                ForEach(points) { point in
                  RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(metric.provider == .postHog ? PRBarTheme.chartPalette[2] : PRBarTheme.chartPalette[0])
                    .frame(width: barWidth, height: barHeight(for: point.value))
                    .accessibilityLabel("\(shortDateLabel(point.date)), \(formatted(point.value))")
                }
              }
              .frame(height: chartHeight, alignment: .bottom)
            }
            .frame(height: chartHeight)

            HStack(alignment: .top, spacing: chartSpacing) {
              ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
                Text(xAxisLabel(for: point.date, index: index))
                  .font(.caption2)
                  .foregroundStyle(.secondary)
                  .frame(width: barWidth)
              }
            }

          }
          .frame(maxWidth: range == .month ? nil : .infinity, alignment: .bottom)
        }
        .scrollIndicators(.hidden)
      }

      if let xAxisTitle {
        Text(xAxisTitle)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, alignment: .center)
          .accessibilityIdentifier("growth-x-axis-title")
      }

      Text("\(points.count) daily points")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(metric.title) trend")
    .accessibilityIdentifier("growth-trend-chart")
    .accessibilityValue(chartAccessibilityValue)
  }

  private var chartAccessibilityValue: String {
    var parts = [
      "\(points.count) points",
      "y-axis \(axisLabel(axisScale.minimum)) to \(axisLabel(axisScale.maximum))",
    ]
    if let xAxisTitle {
      parts.append("x-axis \(xAxisTitle)")
    }
    if let yAxisTitle {
      parts.append("y-axis label \(yAxisTitle)")
    }
    return parts.joined(separator: ", ")
  }

  private func barHeight(for value: Double) -> CGFloat {
    guard axisScale.maximum > 0 else { return 4 }
    return max(CGFloat(value / axisScale.maximum) * chartHeight, 4)
  }

  private func axisTickAlignment(_ index: Int) -> Alignment {
    if index == 0 {
      return .topTrailing
    }
    if index == axisScale.ticks.count - 1 {
      return .bottomTrailing
    }
    return .trailing
  }

  private func formatted(_ value: Double) -> String {
    value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
  }

  private func axisLabel(_ value: Double) -> String {
    switch metric.unit {
    case .count:
      return compactCount(value)
    case .percent:
      let percentValue = value <= 1 ? value * 100 : value
      return "\(formatted(percentValue))%"
    case .position:
      return formatted(value)
    }
  }

  private func compactCount(_ value: Double) -> String {
    let absoluteValue = abs(value)
    if absoluteValue >= 1_000_000 {
      return String(format: value.rounded() == value ? "%.0fM" : "%.1fM", value / 1_000_000)
    }
    if absoluteValue >= 1_000 {
      return String(format: value.rounded() == value ? "%.0fK" : "%.1fK", value / 1_000)
    }
    return formatted(value)
  }

  private func xAxisLabel(for date: Date, index: Int) -> String {
    guard range != .month || index % 5 == 0 || index == points.count - 1 else {
      return ""
    }
    return dayLabel(date)
  }

  private func dayLabel(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "d"
    return formatter.string(from: date)
  }

  private func shortDateLabel(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "MMM d"
    return formatter.string(from: date)
  }

  private func normalizedAxisTitle(_ value: String?) -> String? {
    guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
      value.isEmpty == false
    else {
      return nil
    }
    return value
  }
}

private struct ChartAxisScale {
  var minimum: Double = 0
  var maximum: Double
  var ticks: [Double]

  init(values: [Double]) {
    let maxValue = max(values.max() ?? 0, 1)
    let intervalCount = 4.0
    let step = Self.niceCeiling(maxValue / intervalCount)
    let maximum = max(ceil(maxValue / step) * step, step)
    self.maximum = maximum
    ticks = stride(from: maximum, through: minimum, by: -step).map { $0 }
    if (ticks.last ?? Double.nan) != minimum {
      ticks.append(minimum)
    }
  }

  private static func niceCeiling(_ value: Double) -> Double {
    guard value > 0 else { return 1 }

    let magnitude = pow(10, floor(log10(value)))
    let normalized = value / magnitude
    let niceNormalized: Double

    if normalized <= 1 {
      niceNormalized = 1
    } else if normalized <= 2 {
      niceNormalized = 2
    } else if normalized <= 5 {
      niceNormalized = 5
    } else {
      niceNormalized = 10
    }

    return niceNormalized * magnitude
  }
}
