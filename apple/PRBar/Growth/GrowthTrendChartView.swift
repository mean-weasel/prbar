import SwiftUI

struct GrowthTrendChartView: View {
  var metric: GrowthMetric
  var range: ActivityRange
  var anchorDate: Date

  private var points: [GrowthMetricPoint] {
    metric.normalizedSeries(endingAt: anchorDate, range: range)
  }

  private var maxValue: Double {
    max(points.map(\.value).max() ?? 1, 1)
  }

  private var barWidth: CGFloat {
    range == .month ? 10 : 26
  }

  private var chartSpacing: CGFloat {
    range == .month ? 4 : 8
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(metric.title)
        .font(.headline)

      ScrollView(.horizontal) {
        HStack(alignment: .bottom, spacing: chartSpacing) {
          ForEach(Array(points.enumerated()), id: \.element.id) { index, point in
            VStack(spacing: 6) {
              RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(metric.provider == .postHog ? PRBarTheme.chartPalette[2] : PRBarTheme.chartPalette[0])
                .frame(width: barWidth, height: max(CGFloat(point.value / maxValue) * 120, 4))
                .accessibilityLabel("\(shortDateLabel(point.date)), \(formatted(point.value))")

              Text(xAxisLabel(for: point.date, index: index))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: barWidth + 6)
            }
          }
        }
        .frame(maxWidth: range == .month ? nil : .infinity, alignment: .bottom)
      }
      .frame(height: 150, alignment: .bottom)
      .scrollIndicators(.hidden)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("\(metric.title) trend")
    .accessibilityIdentifier("growth-trend-chart")
    .accessibilityValue("\(points.count) points")
  }

  private func formatted(_ value: Double) -> String {
    value.rounded() == value ? "\(Int(value))" : String(format: "%.1f", value)
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
}
