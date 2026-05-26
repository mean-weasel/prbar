import SwiftUI

struct MonthHeatMapView: View {
  var days: [CalendarDay]
  @Binding var selectedDate: Date
  var countLabel: (Int) -> String

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
  private let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

  init(
    days: [CalendarDay],
    selectedDate: Binding<Date>,
    countLabel: @escaping (Int) -> String = CalendarDay.defaultAccessibilityCountLabel
  ) {
    self.days = days
    self._selectedDate = selectedDate
    self.countLabel = countLabel
  }

  var body: some View {
    LazyVGrid(columns: columns, spacing: 8) {
      ForEach(weekdaySymbols, id: \.self) { symbol in
        Text(symbol)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity)
      }

      ForEach(0..<CalendarDay.leadingWeekdayPlaceholderCount(for: days), id: \.self) { _ in
        Color.clear
          .frame(maxWidth: .infinity, minHeight: 44)
          .accessibilityHidden(true)
      }

      ForEach(days) { day in
        let isSelected = CalendarDay.isSameDay(day.date, selectedDate)

        Button {
          selectedDate = day.date
        } label: {
          Text("\(day.dayNumber)")
            .font(.subheadline.weight(.semibold))
            .monospacedDigit()
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(isSelected ? .white : .primary)
            .background(tileColor(for: day))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(alignment: .topTrailing) {
              if day.count > 0 {
                CalendarCountBadge(count: day.count, isSelected: isSelected)
                  .scaleEffect(0.88)
                  .offset(x: 5, y: -6)
              }
            }
            .padding(.top, 6)
            .padding(.trailing, 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.accessibilityLabel(isSelected: isSelected, countLabel: countLabel))
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
