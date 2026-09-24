//
//  CatalogLocalDataSource.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

protocol CatalogLocalDataSource: Sendable {
    func fetchItems() async throws -> [CatalogItem]
    func save(_ items: [CatalogItem]) async throws
}
