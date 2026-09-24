//
//  DefaultCatalogLocalDataSource.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import Foundation
import SwiftData

@ModelActor
actor DefaultCatalogLocalDataSource: CatalogLocalDataSource {
    func fetchItems() throws -> [CatalogItem] {
        let descriptor = FetchDescriptor<CatalogItemEntity>(sortBy: [SortDescriptor(\.id, order: .reverse)])
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func save(_ items: [CatalogItem]) throws {
        do {
            let stored = try modelContext.fetch(FetchDescriptor<CatalogItemEntity>())
            var byID = Dictionary(uniqueKeysWithValues: stored.map { ($0.id, $0) })
            for item in items {
                if let entity = byID[item.id] {
                    entity.update(with: item)
                } else {
                    let entity = CatalogItemEntity(item: item)
                    modelContext.insert(entity)
                    byID[item.id] = entity
                }
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }
}
