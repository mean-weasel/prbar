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
    VStack(alignment: .leading, spacing: 15) {
      HStack(alignment: .top, spacing: 18) {
        VStack(alignment: .leading, spacing: 2) {
          Text("\(payload.totalPullRequests)")
            .font(.system(size: 52, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .minimumScaleFactor(0.78)
          Text("merged PRs")
            .font(.title3.weight(.heavy))
            .foregroundStyle(.white.opacity(0.9))
        }

        Spacer(minLength: 0)

        VStack(alignment: .trailing, spacing: 5) {
          Text(payload.rangeLabel.capitalized)
            .font(.subheadline.weight(.bold))
          Text("\(payload.activeRepositoryCount) active repos")
            .font(.caption.weight(.medium))
            .foregroundStyle(.white.opacity(0.7))
        }
        .multilineTextAlignment(.trailing)
        .foregroundStyle(.white.opacity(0.82))
      }

      VStack(alignment: .leading, spacing: 6) {
        MiniShareChart(buckets: payload.chartBuckets)
        HStack {
          Text(payload.chartBuckets.first?.label ?? "")
          Spacer()
          Text("Peak \(payload.chartBuckets.map(\.total).max() ?? 0)")
            .monospacedDigit()
          Spacer()
          Text(payload.chartBuckets.last?.label ?? "")
        }
        .font(.system(size: 8, weight: .bold))
        .foregroundStyle(.white.opacity(0.52))
      }

      VStack(alignment: .leading, spacing: 8) {
        ForEach(payload.repoRows.prefix(3)) { row in
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
      .padding(.top, 2)
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
      return 340
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
  var buckets: [ShareCardBucket]

  var body: some View {
    HStack(alignment: .bottom, spacing: 5) {
      ForEach(buckets) { bucket in
        GeometryReader { proxy in
          VStack(spacing: 0) {
            Spacer(minLength: 0)
            VStack(spacing: 0) {
              if bucket.segments.isEmpty {
                RoundedRectangle(cornerRadius: 3)
                  .fill(.white.opacity(0.14))
                  .frame(height: 3)
              } else {
                ForEach(bucket.segments.reversed()) { segment in
                  Rectangle()
                    .fill(Color(hex: segment.colorHex))
                    .frame(height: segmentHeight(segment.value, in: proxy.size.height))
                }
              }
            }
            .clipShape(RoundedRectangle(cornerRadius: 3))
          }
        }
        .frame(maxWidth: .infinity)
      }
    }
    .frame(height: 58)
  }

  private var maxTotal: Int {
    max(buckets.map(\.total).max() ?? 1, 1)
  }

  private func segmentHeight(_ value: Int, in availableHeight: CGFloat) -> CGFloat {
    CGFloat(value) / CGFloat(maxTotal) * max(availableHeight - 2, 1)
  }
}
