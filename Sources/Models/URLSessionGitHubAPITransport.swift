import Foundation

final class URLSessionGitHubAPITransport: GitHubAPITransport {
  private let session: URLSession

  init(session: URLSession = .shared) {
    self.session = session
  }

  func data(for request: URLRequest) throws -> Data {
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

      guard (200..<300).contains(response.statusCode) else {
        box.result = .failure(URLSessionGitHubAPITransportError.httpStatus(response.statusCode))
        return
      }

      box.result = .success(data ?? Data())
    }
    .resume()

    semaphore.wait()
    return try box.result?.get() ?? Data()
  }
}

enum URLSessionGitHubAPITransportError: Error, Equatable {
  case invalidResponse
  case httpStatus(Int)
}

private final class URLSessionTransportResultBox {
  var result: Result<Data, Error>?
}
