//
//  GetCatalogItemsUseCase.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

struct GetCatalogItemsUseCase: Sendable {
    private let repository: any CatalogRepository

    init(repository: any CatalogRepository) {
        self.repository = repository
    }

    func execute() async throws -> [CatalogItem] {
        try await repository.getItems()
    }

    func cachedItems() async throws -> [CatalogItem] {
        try await repository.getCachedItems()
    }
}
