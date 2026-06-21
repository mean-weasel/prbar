import SwiftUI

enum PRBarTheme {
  static let accent = Color(red: 0.20, green: 0.45, blue: 0.96)
  static let chartPalette = [
    Color(red: 0.05, green: 0.65, blue: 0.91),
    Color(red: 0.96, green: 0.62, blue: 0.04),
    Color(red: 0.09, green: 0.73, blue: 0.54),
    Color(red: 0.93, green: 0.29, blue: 0.60),
    Color(red: 0.49, green: 0.39, blue: 0.92),
  ]

  static let surfaceCornerRadius: CGFloat = 8
  static let surfacePadding: CGFloat = 14
  static let sectionSpacing: CGFloat = 16
  static let compactSpacing: CGFloat = 8
  static let surfaceBackground = Color(.secondarySystemBackground)
  static let selectedSurfaceBackground = accent.opacity(0.12)
  static let separator = Color(.separator).opacity(0.24)

  static func repositoryColor(_ hex: String) -> Color {
    let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    guard let value = UInt64(trimmed, radix: 16) else {
      return accent
    }

    return Color(
      red: Double((value & 0xff0000) >> 16) / 255,
      green: Double((value & 0x00ff00) >> 8) / 255,
      blue: Double(value & 0x0000ff) / 255
    )
  }
}

extension View {
  func prbarSurface(isSelected: Bool = false, strokeColor: Color = .clear) -> some View {
    padding(PRBarTheme.surfacePadding)
      .background(isSelected ? PRBarTheme.selectedSurfaceBackground : PRBarTheme.surfaceBackground)
      .overlay(
        RoundedRectangle(cornerRadius: PRBarTheme.surfaceCornerRadius, style: .continuous)
          .stroke(strokeColor, lineWidth: strokeColor == .clear ? 0 : 1)
      )
      .clipShape(RoundedRectangle(cornerRadius: PRBarTheme.surfaceCornerRadius, style: .continuous))
  }
}
