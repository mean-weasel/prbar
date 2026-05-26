import SwiftUI

struct MonthHeatMapView: View {
  var days: [CalendarDay]
  @Binding var selectedDate: Date

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

  var body: some View {
    LazyVGrid(columns: columns, spacing: 8) {
      ForEach(days) { day in
        Button {
          selectedDate = day.date
        } label: {
          VStack(spacing: 3) {
            Text("\(day.dayNumber)")
              .font(.subheadline.weight(.semibold))
              .monospacedDigit()
            if day.count > 0 {
              Text("\(day.count)")
                .font(.caption2.weight(.semibold))
                .monospacedDigit()
            }
          }
          .frame(maxWidth: .infinity, minHeight: 44)
          .foregroundStyle(CalendarDay.isSameDay(day.date, selectedDate) ? .white : .primary)
          .background(tileColor(for: day))
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.accessibilityLabel)
      }
    }
  }

  private func tileColor(for day: CalendarDay) -> Color {
    if CalendarDay.isSameDay(day.date, selectedDate) {
      return PRBarTheme.accent
    }

    if day.count > 0 {
      return PRBarTheme.accent.opacity(0.18 + min(Double(day.count), 6) * 0.08)
    }

    return Color(.secondarySystemBackground)
  }
}

#Preview {
  @Previewable @State var selectedDate = SampleData.today
  let days = CalendarDay.days(endingAt: SampleData.today, range: .month)

  MonthHeatMapView(days: days, selectedDate: $selectedDate)
    .padding()
}
