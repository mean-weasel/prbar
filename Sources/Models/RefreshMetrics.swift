import Foundation
import OSLog

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

final class OSLogRefreshMetricsRecorder: RefreshMetricsRecording {
  private let logger: Logger

  init(
    subsystem: String = "com.neonwatty.PRMenuBar",
    category: String = "refresh"
  ) {
    logger = Logger(subsystem: subsystem, category: category)
  }

  func record(_ event: RefreshMetricEvent) {
    let metadata = event.metadata
      .sorted { $0.key < $1.key }
      .map { "\($0.key)=\($0.value)" }
      .joined(separator: " ")
    logger.info(
      "refresh_metric name=\(event.name, privacy: .public) duration_ms=\(event.durationMilliseconds, privacy: .public) metadata=\(metadata, privacy: .public)"
    )
  }
}
