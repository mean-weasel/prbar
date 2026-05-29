import Foundation

extension GitHubPRActivityProvider {
  func discoveryData(for apiRequest: GitHubAPIRequest) throws -> Data {
    let key = apiRequest.cacheKey
    let cachedResponse = discoveryResponseCache[key]
    let request = try apiRequest.urlRequest(token: token, eTag: cachedResponse?.eTag)
    let response = try transport.response(for: request)
    let conditionalMetadata = [
      "path": apiRequest.path,
      "result": conditionalResult(
        response: response,
        hadValidator: cachedResponse?.eTag != nil
      ),
    ]
    recordMetric("http.conditional", metadata: conditionalMetadata)

    if response.isNotModified {
      guard let cachedResponse else {
        throw GitHubPRActivityProviderError.notModifiedWithoutCachedData
      }
      return cachedResponse.data
    }

    if let eTag = response.eTag {
      discoveryResponseCache[key] = GitHubCachedAPIResponse(data: response.data, eTag: eTag)
    }
    return response.data
  }

  private func conditionalResult(response: GitHubAPIResponse, hadValidator: Bool) -> String {
    if response.isNotModified {
      return "not_modified"
    }
    return hadValidator ? "modified" : "uncached"
  }
}

struct GitHubCachedAPIResponse: Codable, Equatable {
  var data: Data
  var eTag: String
}

extension GitHubAPIRequest {
  fileprivate var cacheKey: String {
    let query =
      queryItems
      .map { "\($0.name)=\($0.value ?? "")" }
      .sorted()
      .joined(separator: "&")

    return query.isEmpty ? path : "\(path)?\(query)"
  }
}
