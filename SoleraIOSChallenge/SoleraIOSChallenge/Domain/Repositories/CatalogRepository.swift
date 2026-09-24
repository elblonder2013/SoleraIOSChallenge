//
//  CatalogRepository.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

protocol CatalogRepository: Sendable {
    func getItems() async throws -> [CatalogItem]
    func getOlderItems(maxID: String) async throws -> [CatalogItem]
    func getNewerItems(sinceID: String) async throws -> [CatalogItem]
}
