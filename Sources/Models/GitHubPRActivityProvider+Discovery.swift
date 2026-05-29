import Foundation

extension GitHubPRActivityProvider {
  func discovery(now: Date) throws -> GitHubDiscoveryResult {
    if let discoveryCache,
      now.timeIntervalSince(discoveryCache.createdAt) < discoveryCacheDuration
    {
      recordMetric("discovery.cache_hit", metadata: ["cache": "hit"])
      return GitHubDiscoveryResult(cache: discoveryCache, cacheHit: true)
    }

    if let persistedDiscovery = discoveryCacheStore?.load(token: token) {
      if now.timeIntervalSince(persistedDiscovery.cache.createdAt) < discoveryCacheDuration {
        discoveryCache = persistedDiscovery.cache
        discoveryResponseCache = persistedDiscovery.responseCache
        recordMetric("discovery.cache_hit", metadata: ["cache": "persisted"])
        return GitHubDiscoveryResult(cache: persistedDiscovery.cache, cacheHit: true)
      }
      if discoveryResponseCache.isEmpty {
        discoveryResponseCache = persistedDiscovery.responseCache
      }
    }

    return try measured("discovery.total", metadata: ["cache": "miss"]) {
      let repositories = try repositories()
      let pullableRepositories = repositories.filter(\.canPull)
      if pullableRepositories.isEmpty {
        let discovery = GitHubDiscoveryCache(
          createdAt: now,
          authenticatedUser: GitHubAuthenticatedUser(login: ""),
          searchOwners: [],
          pullableRepositories: []
        )
        saveDiscovery(discovery)
        return GitHubDiscoveryResult(cache: discovery, cacheHit: false)
      }

      let authenticatedUser = try authenticatedUser()
      let discovery = GitHubDiscoveryCache(
        createdAt: now,
        authenticatedUser: authenticatedUser,
        searchOwners: try searchOwners(authenticatedUser: authenticatedUser),
        pullableRepositories: pullableRepositories
      )
      saveDiscovery(discovery)
      return GitHubDiscoveryResult(cache: discovery, cacheHit: false)
    }
  }

  private func saveDiscovery(_ cache: GitHubDiscoveryCache) {
    discoveryCache = cache
    discoveryCacheStore?.save(
      GitHubPersistedDiscoveryCache(
        cache: cache,
        responseCache: discoveryResponseCache
      ),
      token: token
    )
  }

  private func authenticatedUser() throws -> GitHubAuthenticatedUser {
    try measured("discovery.authenticated_user") {
      let data = try discoveryData(for: GitHubAPIRequest.authenticatedUser())
      return try JSONDecoder().decode(GitHubAuthenticatedUser.self, from: data)
    }
  }

  private func organizations() throws -> [GitHubOrganization] {
    try measured("discovery.organizations") {
      let data = try discoveryData(for: GitHubAPIRequest.userOrganizations())
      return try JSONDecoder().decode([GitHubOrganization].self, from: data)
    }
  }

  private func searchOwners(authenticatedUser: GitHubAuthenticatedUser) throws
    -> [GitHubSearchOwner]
  {
    let userOwner = GitHubSearchOwner(kind: .user, login: authenticatedUser.login)
    let organizationOwners = try organizations().map {
      GitHubSearchOwner(kind: .org, login: $0.login)
    }
    return ([userOwner] + organizationOwners).sorted {
      if $0.kind.rawValue == $1.kind.rawValue {
        return $0.login < $1.login
      }
      return $0.kind.rawValue < $1.kind.rawValue
    }
  }

  private func repositories() throws -> [GitHubRepository] {
    var page = 1
    var repositories: [GitHubRepository] = []
    var pageRepositories: [GitHubRepository]

    repeat {
      pageRepositories = try measured(
        "discovery.repositories.page",
        metadata: ["page": "\(page)"]
      ) {
        let apiRequest = GitHubAPIRequest.userRepositories(
          page: page,
          perPage: repositoryPageSize
        )
        let data = try discoveryData(for: apiRequest)
        return try JSONDecoder().decode([GitHubRepository].self, from: data)
      }
      repositories.append(contentsOf: pageRepositories)
      page += 1
    } while pageRepositories.count == repositoryPageSize

    return repositories
  }
}
