//
//  CatalogRemoteDataSource.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

protocol CatalogRemoteDataSource: Sendable {
    func getItems() async throws -> [CatalogItemDTO]
    func getOlderItems(maxID: String) async throws -> [CatalogItemDTO]
    func getNewerItems(sinceID: String) async throws -> [CatalogItemDTO]
}
