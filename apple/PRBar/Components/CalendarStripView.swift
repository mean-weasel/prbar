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
    .padding(.trailing, 12)
  }
}

private struct CalendarDateButton: View {
  var day: CalendarDay
  var isSelected: Bool
  var countLabel: (Int) -> String
  var action: () -> Void

  var body: some View {
    Button(action: action) {
      Text("\(day.dayNumber)")
        .font(.headline)
        .monospacedDigit()
        .frame(maxWidth: .infinity, minHeight: 56)
        .foregroundStyle(isSelected ? .white : .primary)
        .background(isSelected ? PRBarTheme.accent : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(alignment: .topTrailing) {
          if day.count > 0 {
            CalendarCountBadge(count: day.count, isSelected: isSelected)
              .offset(x: 6, y: -7)
          }
        }
        .padding(.top, 7)
        .padding(.trailing, 8)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(day.accessibilityLabel(isSelected: isSelected, countLabel: countLabel))
  }
}

struct CalendarCountBadge: View {
  var count: Int
  var isSelected: Bool

  var body: some View {
    Text("\(count)")
      .font(.system(size: 10, weight: .bold, design: .rounded))
      .monospacedDigit()
      .foregroundStyle(isSelected ? PRBarTheme.accent : .white)
      .frame(minWidth: 17, minHeight: 17)
      .padding(.horizontal, count > 9 ? 3 : 0)
      .background(isSelected ? Color.white : PRBarTheme.accent)
      .clipShape(Capsule())
      .overlay {
        Capsule()
          .stroke(
            isSelected ? PRBarTheme.accent.opacity(0.55) : Color(.systemBackground).opacity(0.75),
            lineWidth: 1
          )
      }
      .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
      .accessibilityHidden(true)
  }
}

#Preview {
  @Previewable @State var selectedDate = SampleData.today
  let days = CalendarDay.days(endingAt: SampleData.today, range: .week)

  CalendarStripView(days: days, selectedDate: $selectedDate)
    .padding()
}
