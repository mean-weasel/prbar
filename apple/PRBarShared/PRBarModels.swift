import Foundation

struct Repository: Identifiable, Equatable {
  enum Visibility: String, CaseIterable, Codable {
    case `public`
    case `private`
  }

  enum Access: String, CaseIterable, Codable {
    case ready
    case sso
  }

  var id: String
  var owner: String
  var name: String
  var visibility: Visibility
  var colorHex: String
  var included: Bool
  var recommended: Bool
  var access: Access
  var reason: String
}

struct PullRequest: Identifiable, Equatable {
  var id: String
  var title: String
  var repoID: Repository.ID
  var number: Int
  var mergedAt: Date
}

struct ReleaseMoment: Identifiable, Equatable {
  enum Source: String, CaseIterable, Codable {
    case release
    case tag
  }

  var id: String
  var repoID: Repository.ID
  var title: String
  var tag: String
  var date: Date
  var source: Source
  var notes: String
  var url: URL
}

enum ActivityRange: String, CaseIterable, Identifiable {
  case day
  case week
  case month

  var id: String { rawValue }
}

struct CalendarDay: Identifiable, Equatable {
  var date: Date
  var count: Int

  var id: Date { date }

  var dayNumber: Int {
    Self.calendar.component(.day, from: date)
  }

  var monthName: String {
    let formatter = DateFormatter()
    formatter.calendar = Self.calendar
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = Self.calendar.timeZone
    formatter.dateFormat = "MMMM"
    return formatter.string(from: date)
  }

  func accessibilityLabel(isSelected: Bool) -> String {
    var label = "\(monthName) \(dayNumber), \(isSelected ? "selected" : "not selected")"
    if count > 0 {
      label += ", \(count) \(count == 1 ? "pull request" : "pull requests")"
    }
    return label
  }

  static func days(endingAt endDate: Date, range: ActivityRange) -> [CalendarDay] {
    let endOfDay = calendar.startOfDay(for: endDate)

    if range == .month {
      let components = calendar.dateComponents([.year, .month], from: endOfDay)
      guard
        let start = calendar.date(from: components),
        let interval = calendar.range(of: .day, in: .month, for: endOfDay)
      else {
        return []
      }

      return interval.compactMap { offset in
        calendar.date(byAdding: .day, value: offset - 1, to: start).map { CalendarDay(date: $0, count: 0) }
      }
    }

    let count = range == .day ? 5 : 7
    return (0..<count).compactMap { offset in
      calendar.date(byAdding: .day, value: offset - count + 1, to: endOfDay).map { CalendarDay(date: $0, count: 0) }
    }
  }

  static func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
    calendar.isDate(lhs, inSameDayAs: rhs)
  }

  static func leadingWeekdayPlaceholderCount(for days: [CalendarDay]) -> Int {
    guard let firstDay = days.first else { return 0 }

    return calendar.component(.weekday, from: firstDay.date) - 1
  }

  private static let calendar: Calendar = {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    return calendar
  }()
}

enum CardSide: String, CaseIterable, Identifiable {
  case publicSide
  case evidenceSide

  var id: String { rawValue }
}

struct WorkCardDraft: Equatable {
  enum Source: Equatable {
    case shippingSnapshot
    case releaseReceipt(ReleaseMoment.ID)
  }

  enum Theme: String, CaseIterable, Identifiable {
    case clean
    case terminal
    case launch
    case hype
    case minimal

    var id: String { rawValue }
  }

  var source: Source
  var theme: Theme
  var side: CardSide
  var showRepos: Bool
  var showHandle: Bool
  var exactCounts: Bool
  var showPrivateLabels: Bool
}
