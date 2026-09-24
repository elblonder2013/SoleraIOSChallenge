//
//  DefaultCatalogRemoteDataSource.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import Foundation

struct DefaultCatalogRemoteDataSource: CatalogRemoteDataSource {
    private let client: any APIClient

    init(client: any APIClient) {
        self.client = client
    }

    func getItems() async throws -> [CatalogItemDTO] {
        try await client.request(Endpoint(path: "v1/items"))
    }

    func getOlderItems(maxID: String) async throws -> [CatalogItemDTO] {
        try await client.request(Endpoint(
            path: "v1/items", queryItems: [URLQueryItem(name: "max_id", value: maxID)]
        ))
    }

    func getNewerItems(sinceID: String) async throws -> [CatalogItemDTO] {
        try await client.request(Endpoint(
            path: "v1/items", queryItems: [URLQueryItem(name: "since_id", value: sinceID)]
        ))
    }
}
