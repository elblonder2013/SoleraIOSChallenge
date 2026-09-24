//
//  CatalogPersistenceTests.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import SwiftData
import XCTest
@testable import SoleraIOSChallenge

@MainActor
final class CatalogPersistenceTests: XCTestCase {
    func testSavingUpdatesDuplicatesAndPreservesOtherItems() async throws {
        let container = try ModelContainer(
            for: CatalogItemEntity.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let local = DefaultCatalogLocalDataSource(modelContainer: container)
        let first = try item("01")
        let second = try item("02")
        try await local.save([first, second, second])
        let updated = try item("02", description: "Updated photo")
        try await local.save([updated])

        let items = try await local.fetchItems()
        XCTAssertEqual(items, [updated, first])
    }

    func testItemsSurviveOpeningTheStoreAgain() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("catalog.store")
        let expected = try item("01")
        try await saveInSeparateContainer(expected, url: url)

        let reopened = try ModelContainer(
            for: CatalogItemEntity.self, configurations: ModelConfiguration(url: url)
        )
        let local = DefaultCatalogLocalDataSource(modelContainer: reopened)
        let items = try await local.fetchItems()
        XCTAssertEqual(items, [expected])
    }

    private func saveInSeparateContainer(_ item: CatalogItem, url: URL) async throws {
        let container = try ModelContainer(
            for: CatalogItemEntity.self, configurations: ModelConfiguration(url: url)
        )
        let local = DefaultCatalogLocalDataSource(modelContainer: container)
        try await local.save([item])
    }

    private func item(_ id: String, description: String = "Photo") throws -> CatalogItem {
        CatalogItem(id: id, imageURL: try XCTUnwrap(URL(string: "https://example.com/image.png")),
                    description: description, confidence: 0.96)
    }
}
