//
//  LoadMoreCatalogItemsUseCase.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

struct LoadMoreCatalogItemsUseCase: Sendable {
    private let repository: any CatalogRepository

    init(repository: any CatalogRepository) {
        self.repository = repository
    }

    func execute(maxID: String) async throws -> [CatalogItem] {
        try await repository.getOlderItems(maxID: maxID)
    }
}
