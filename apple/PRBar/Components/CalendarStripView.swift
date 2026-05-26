import SwiftUI

struct CalendarStripView: View {
  var days: [CalendarDay]
  @Binding var selectedDate: Date
  var countLabel: (Int) -> String

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
    HStack(spacing: 8) {
      ForEach(days) { day in
        CalendarDateButton(
          day: day,
          isSelected: CalendarDay.isSameDay(day.date, selectedDate),
          countLabel: countLabel
        ) {
          selectedDate = day.date
        }
        .frame(maxWidth: .infinity)
      }
    }
  }
}

private struct CalendarDateButton: View {
  var day: CalendarDay
  var isSelected: Bool
  var countLabel: (Int) -> String
  var action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Text("\(day.dayNumber)")
          .font(.headline)
          .monospacedDigit()
        if day.count > 0 {
          Text("\(day.count)")
            .font(.caption2.weight(.semibold))
            .monospacedDigit()
        }
      }
      .frame(maxWidth: .infinity, minHeight: 56)
      .foregroundStyle(isSelected ? .white : .primary)
      .background(isSelected ? PRBarTheme.accent : Color(.secondarySystemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
    .buttonStyle(.plain)
    .accessibilityLabel(day.accessibilityLabel(isSelected: isSelected, countLabel: countLabel))
  }
}

#Preview {
  @Previewable @State var selectedDate = SampleData.today
  let days = CalendarDay.days(endingAt: SampleData.today, range: .week)

  CalendarStripView(days: days, selectedDate: $selectedDate)
    .padding()
}
