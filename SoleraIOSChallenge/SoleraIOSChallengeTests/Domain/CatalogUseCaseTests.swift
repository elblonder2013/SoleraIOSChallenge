//
//  CatalogUseCaseTests.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import XCTest
@testable import SoleraIOSChallenge

@MainActor
final class CatalogUseCaseTests: XCTestCase {
    func testInitialLoadReturnsRepositoryItems() async throws {
        let items = try makeItems()
        let repository = RepositorySpy(result: .success(items))

        let result = try await GetCatalogItemsUseCase(repository: repository).execute()

        XCTAssertEqual(result, items)
        let calls = await repository.calls
        XCTAssertEqual(calls, [.initial])
    }

    func testLoadMoreForwardsInclusiveMaxID() async throws {
        let items = try makeItems()
        let repository = RepositorySpy(result: .success(items))

        let result = try await LoadMoreCatalogItemsUseCase(repository: repository)
            .execute(maxID: "item-10")

        XCTAssertEqual(result, items)
        let calls = await repository.calls
        XCTAssertEqual(calls, [.older("item-10")])
    }

    func testRefreshForwardsSinceID() async throws {
        let items = try makeItems()
        let repository = RepositorySpy(result: .success(items))

        let result = try await RefreshCatalogItemsUseCase(repository: repository)
            .execute(sinceID: "item-30")

        XCTAssertEqual(result, items)
        let calls = await repository.calls
        XCTAssertEqual(calls, [.newer("item-30")])
    }

    func testEveryUseCasePropagatesRepositoryFailure() async {
        let repository = RepositorySpy(result: .failure(.unavailable))
        let operations: [@Sendable () async throws -> [CatalogItem]] = [
            { try await GetCatalogItemsUseCase(repository: repository).execute() },
            { try await LoadMoreCatalogItemsUseCase(repository: repository).execute(maxID: "10") },
            { try await RefreshCatalogItemsUseCase(repository: repository).execute(sinceID: "30") }
        ]

        for operation in operations {
            do {
                _ = try await operation()
                XCTFail("Expected the repository error")
            } catch {
                XCTAssertEqual(error as? RepositorySpy.Failure, .unavailable)
            }
        }
    }

    private func makeItems() throws -> [CatalogItem] {
        let url = try XCTUnwrap(URL(string: "https://example.com/photo.jpg"))
        return [CatalogItem(id: "item-30", imageURL: url, description: "A photo", confidence: 0.9)]
    }
}

private actor RepositorySpy: CatalogRepository {
    enum Call: Equatable {
        case initial
        case older(String)
        case newer(String)
    }

    enum Failure: Error { case unavailable }

    private let result: Result<[CatalogItem], Failure>
    private(set) var calls: [Call] = []

    init(result: Result<[CatalogItem], Failure>) {
        self.result = result
    }

    func getCachedItems() async throws -> [CatalogItem] { [] }

    func getItems() async throws -> [CatalogItem] {
        calls.append(.initial)
        return try result.get()
    }

    func getOlderItems(maxID: String) async throws -> [CatalogItem] {
        calls.append(.older(maxID))
        return try result.get()
    }

    func getNewerItems(sinceID: String) async throws -> [CatalogItem] {
        calls.append(.newer(sinceID))
        return try result.get()
    }
}
