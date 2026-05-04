import Foundation

protocol PRActivityProviding {
  func load(now: Date) throws -> PRActivityStore
}

struct StaticPRActivityProvider: PRActivityProviding {
  func load(now: Date = Date()) throws -> PRActivityStore {
    PRActivityStore.sample(now: now)
  }
}

struct JSONPRActivityProvider: PRActivityProviding {
  var data: Data

  func load(now: Date = Date()) throws -> PRActivityStore {
    if let store = try? JSONDecoder().decode(PRActivityStore.self, from: data) {
      return store
    }
    let payload = try JSONDecoder().decode(PRActivityPayload.self, from: data)
    return PRActivityStore(
      bucketLabels: payload.bucketLabels,
      window: payload.defaultWindow,
      bin: .week,
      refreshInterval: .daily,
      repositories: payload.repositories,
      refreshedAt: now
    )
  }
}

struct FilePRActivityProvider: PRActivityProviding {
  var path: String

  func load(now: Date = Date()) throws -> PRActivityStore {
    let url = URL(fileURLWithPath: path)
    return try JSONPRActivityProvider(data: Data(contentsOf: url)).load(now: now)
  }
}

private struct PRActivityPayload: Codable {
  var bucketLabels: [String]
  var defaultWindow: ActivityWindow
  var repositories: [RepositoryActivity]
}
