import Foundation

struct RefreshMetricEvent: Codable, Equatable {
  var name: String
  var durationMilliseconds: Double
  var metadata: [String: String]
}

protocol RefreshMetricsRecording: AnyObject {
  func record(_ event: RefreshMetricEvent)
}

final class RefreshMetricsCollector: RefreshMetricsRecording {
  private let lock = NSLock()
  private var storedEvents: [RefreshMetricEvent] = []

  var events: [RefreshMetricEvent] {
    lock.lock()
    defer {
      lock.unlock()
    }
    return storedEvents
  }

  func record(_ event: RefreshMetricEvent) {
    lock.lock()
    storedEvents.append(event)
    lock.unlock()
  }

  func reset() {
    lock.lock()
    storedEvents.removeAll()
    lock.unlock()
  }
}
