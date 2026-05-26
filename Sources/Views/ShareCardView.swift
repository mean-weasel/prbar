import SwiftUI

struct ShareCardView: View {
  var payload: ShareCardPayload

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 14)
        .fill(backgroundGradient)
      VStack(alignment: .leading, spacing: 14) {
        Text(kicker)
          .font(.caption2.weight(.heavy))
          .textCase(.uppercase)
          .foregroundStyle(.white.opacity(0.72))
        content
        Spacer(minLength: 0)
        HStack {
          Text("@neonwatty")
          Spacer()
          Text("PRBAR.APP")
        }
        .font(.caption2.weight(.heavy))
        .foregroundStyle(.white.opacity(0.72))
      }
      .padding(20)
    }
    .frame(width: 360, height: payloadHeight)
    .foregroundStyle(.white)
  }

  @ViewBuilder
  private var content: some View {
    switch payload {
    case .prActivity(let payload):
      prContent(payload)
    case .release(let payload):
      releaseContent(payload)
    }
  }

  private func prContent(_ payload: PRShareCardPayload) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(payload.headline)
        .font(.system(size: 30, weight: .heavy, design: .rounded))
        .lineLimit(2)
      Text(
        "\(payload.activeRepositoryCount) active repos, with private repository names hidden by default."
      )
      .font(.caption)
      .foregroundStyle(.white.opacity(0.78))
      MiniShareChart(values: payload.bucketTotals)
      VStack(spacing: 7) {
        ForEach(payload.repoRows.prefix(4)) { row in
          HStack(spacing: 8) {
            Circle()
              .fill(Color(hex: row.colorHex))
              .frame(width: 7, height: 7)
            Text(row.displayName)
              .lineLimit(1)
            Spacer()
            Text("\(row.count)")
              .monospacedDigit()
          }
          .font(.caption.weight(.semibold))
        }
      }
      .padding(10)
      .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(.white.opacity(0.14))
      )
    }
  }

  private func releaseContent(_ payload: ReleaseShareCardPayload) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(payload.headline)
        .font(.system(size: 28, weight: .heavy, design: .rounded))
        .lineLimit(2)
      Text("\(payload.repositoryDisplayName) · \(payload.dateLabel)")
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.white.opacity(0.78))
      Text(payload.notesExcerpt)
        .font(.subheadline)
        .foregroundStyle(.white.opacity(0.8))
        .lineLimit(5)
    }
  }

  private var kicker: String {
    switch payload {
    case .prActivity(let payload):
      return "PRBar · \(payload.rangeLabel) proof of work"
    case .release(let payload):
      return "PRBar · \(payload.sourceLabel)"
    }
  }

  private var payloadHeight: CGFloat {
    switch payload {
    case .prActivity:
      return 300
    case .release:
      return 240
    }
  }

  private var backgroundGradient: LinearGradient {
    switch payload {
    case .prActivity:
      return LinearGradient(
        colors: [
          Color(red: 0.04, green: 0.09, blue: 0.18),
          Color(red: 0.02, green: 0.28, blue: 0.22),
        ],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
      )
    case .release:
      return LinearGradient(
        colors: [
          Color(red: 0.05, green: 0.08, blue: 0.16),
          Color(red: 0.04, green: 0.22, blue: 0.36),
        ],
        startPoint: .bottomLeading,
        endPoint: .topTrailing
      )
    }
  }
}

private struct MiniShareChart: View {
  var values: [Int]

  var body: some View {
    HStack(alignment: .bottom, spacing: 6) {
      ForEach(Array(values.enumerated()), id: \.offset) { _, value in
        RoundedRectangle(cornerRadius: 4)
          .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom))
          .frame(height: height(for: value))
      }
    }
    .frame(height: 44)
  }

  private func height(for value: Int) -> CGFloat {
    let maxValue = max(values.max() ?? 1, 1)
    return max(CGFloat(value) / CGFloat(maxValue) * 42, value > 0 ? 8 : 4)
  }
}
