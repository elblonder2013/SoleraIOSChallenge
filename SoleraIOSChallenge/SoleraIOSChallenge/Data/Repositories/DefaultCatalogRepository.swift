//
//  DefaultCatalogRepository.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

struct DefaultCatalogRepository: CatalogRepository {
    private let remote: any CatalogRemoteDataSource
    private let local: any CatalogLocalDataSource

    init(remote: any CatalogRemoteDataSource, local: any CatalogLocalDataSource) {
        self.remote = remote
        self.local = local
    }

    func getCachedItems() async throws -> [CatalogItem] {
        try await local.fetchItems()
    }

    func getItems() async throws -> [CatalogItem] {
        let items: [CatalogItem]
        do {
            items = try await remote.getItems().map { $0.toDomain() }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            let cached = try await local.fetchItems()
            guard !cached.isEmpty else { throw error }
            return cached
        }
        try Task.checkCancellation()
        try await local.save(items)
        return try await local.fetchItems()
    }

    func getOlderItems(maxID: String) async throws -> [CatalogItem] {
        let items = try await remote.getOlderItems(maxID: maxID).map { $0.toDomain() }
        try Task.checkCancellation()
        try await local.save(items)
        return items
    }

    func getNewerItems(sinceID: String) async throws -> [CatalogItem] {
        let items = try await remote.getNewerItems(sinceID: sinceID).map { $0.toDomain() }
        try Task.checkCancellation()
        try await local.save(items)
        return items
    }
}
