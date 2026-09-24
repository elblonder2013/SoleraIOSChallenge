//
//  DefaultCatalogRepository.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

struct DefaultCatalogRepository: CatalogRepository {
    private let remote: any CatalogRemoteDataSource

    init(remote: any CatalogRemoteDataSource) {
        self.remote = remote
    }

    func getItems() async throws -> [CatalogItem] {
        try await remote.getItems().map { $0.toDomain() }
    }

    func getOlderItems(maxID: String) async throws -> [CatalogItem] {
        try await remote.getOlderItems(maxID: maxID).map { $0.toDomain() }
    }

    func getNewerItems(sinceID: String) async throws -> [CatalogItem] {
        try await remote.getNewerItems(sinceID: sinceID).map { $0.toDomain() }
    }
}
