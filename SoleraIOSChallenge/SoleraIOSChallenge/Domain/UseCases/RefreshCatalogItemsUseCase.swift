//
//  RefreshCatalogItemsUseCase.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

struct RefreshCatalogItemsUseCase: Sendable {
    private let repository: any CatalogRepository

    init(repository: any CatalogRepository) {
        self.repository = repository
    }

    func execute(sinceID: String) async throws -> [CatalogItem] {
        try await repository.getNewerItems(sinceID: sinceID)
    }
}
