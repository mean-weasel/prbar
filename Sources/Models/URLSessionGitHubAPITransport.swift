import Foundation

final class URLSessionGitHubAPITransport: GitHubAPITransport {
  private let session: URLSession

  init(session: URLSession = .shared) {
    self.session = session
  }

  func response(for request: URLRequest) throws -> GitHubAPIResponse {
    let semaphore = DispatchSemaphore(value: 0)
    let box = URLSessionTransportResultBox()

    session.dataTask(with: request) { data, response, error in
      defer {
        semaphore.signal()
      }

      if let error {
        box.result = .failure(error)
        return
      }

      guard let response = response as? HTTPURLResponse else {
        box.result = .failure(URLSessionGitHubAPITransportError.invalidResponse)
        return
      }

      if response.statusCode == 304 {
        box.result = .success(
          GitHubAPIResponse(
            data: Data(),
            eTag: response.value(forHTTPHeaderField: "ETag"),
            statusCode: response.statusCode
          )
        )
        return
      }

      guard (200..<300).contains(response.statusCode) else {
        box.result = .failure(
          URLSessionGitHubAPITransportError.httpStatus(
            response.statusCode,
            rateLimitReset: response.rateLimitResetDate
          )
        )
        return
      }

      box.result = .success(
        GitHubAPIResponse(
          data: data ?? Data(),
          eTag: response.value(forHTTPHeaderField: "ETag"),
          statusCode: response.statusCode
        )
      )
    }
    .resume()

    semaphore.wait()
    return try box.result?.get() ?? GitHubAPIResponse(data: Data())
  }
}

enum URLSessionGitHubAPITransportError: Error, Equatable {
  case invalidResponse
  case httpStatus(Int, rateLimitReset: Date? = nil)
}

private final class URLSessionTransportResultBox {
  var result: Result<GitHubAPIResponse, Error>?
}

extension HTTPURLResponse {
  fileprivate var rateLimitResetDate: Date? {
    guard
      let text = value(forHTTPHeaderField: "X-RateLimit-Reset"),
      let seconds = TimeInterval(text)
    else {
      return nil
    }

    return Date(timeIntervalSince1970: seconds)
  }
}
