import Foundation

struct GitHubAPIRequest: Equatable {
  var path: String
  var queryItems: [URLQueryItem] = []

  func urlRequest(token: String, baseURL: URL = URL(string: "https://api.github.com")!) throws
    -> URLRequest
  {
    let urlComponents = URLComponents(
      url: baseURL.appendingPathComponent(path),
      resolvingAgainstBaseURL: false
    )
    guard var components = urlComponents else {
      throw GitHubAPIRequestError.invalidURL
    }
    components.queryItems = queryItems.isEmpty ? nil : queryItems

    guard let url = components.url else {
      throw GitHubAPIRequestError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
    return request
  }

  static func userRepositories(page: Int = 1, perPage: Int = 100) -> GitHubAPIRequest {
    GitHubAPIRequest(
      path: "/user/repos",
      queryItems: [
        URLQueryItem(name: "affiliation", value: "owner,collaborator,organization_member"),
        URLQueryItem(name: "sort", value: "pushed"),
        URLQueryItem(name: "direction", value: "desc"),
        URLQueryItem(name: "per_page", value: "\(perPage)"),
        URLQueryItem(name: "page", value: "\(page)"),
      ]
    )
  }
}

enum GitHubAPIRequestError: Error, Equatable {
  case invalidURL
}
