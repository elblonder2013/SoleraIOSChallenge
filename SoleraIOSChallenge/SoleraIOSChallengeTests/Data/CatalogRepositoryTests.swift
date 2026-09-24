//
//  CatalogRepositoryTests.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import XCTest
@testable import SoleraIOSChallenge

@MainActor
final class CatalogRepositoryTests: XCTestCase {
    func testInitialRequestMapsAndSavesRemoteItemsWithoutLosingOlderCache() async throws {
        let dto = try makeDTO("30")
        let older = try makeDTO("20").toDomain()
        let local = LocalStub(items: [older])
        let repository = DefaultCatalogRepository(remote: RemoteStub(result: .success([dto])), local: local)
        let result = try await repository.getItems()
        XCTAssertEqual(result, [dto.toDomain(), older])
        let saved = await local.saved
        XCTAssertEqual(saved, [dto.toDomain()])
    }

    func testCacheReadDoesNotMakeARemoteRequest() async throws {
        let cached = try makeDTO("30").toDomain()
        let remote = RemoteStub(result: .failure(Failure.offline))
        let repository = DefaultCatalogRepository(remote: remote, local: LocalStub(items: [cached]))
        let result = try await repository.getCachedItems()
        XCTAssertEqual(result, [cached])
        let calls = await remote.calls
        XCTAssertTrue(calls.isEmpty)
    }

    func testRemoteFailureFallsBackToCachedItems() async throws {
        let cached = try makeDTO("30").toDomain()
        let repository = DefaultCatalogRepository(
            remote: RemoteStub(result: .failure(Failure.offline)), local: LocalStub(items: [cached])
        )
        let result = try await repository.getItems()
        XCTAssertEqual(result, [cached])
    }

    func testRemoteFailureWithoutCacheIsPropagated() async throws {
        let repository = DefaultCatalogRepository(
            remote: RemoteStub(result: .failure(Failure.offline)), local: LocalStub()
        )
        do {
            _ = try await repository.getItems()
            XCTFail("Expected the remote error")
        } catch Failure.offline {}
    }

    func testSuccessfulEmptyResponseIsNotAnError() async throws {
        let repository = DefaultCatalogRepository(remote: RemoteStub(result: .success([])), local: LocalStub())
        let result = try await repository.getItems()
        XCTAssertTrue(result.isEmpty)
    }

    func testPaginationAndRefreshSaveResultsAndForwardCursors() async throws {
        let dto = try makeDTO("29")
        let remote = RemoteStub(result: .success([dto]))
        let local = LocalStub()
        let repository = DefaultCatalogRepository(remote: remote, local: local)
        let older = try await repository.getOlderItems(maxID: "30")
        let newer = try await repository.getNewerItems(sinceID: "20")
        XCTAssertEqual(older, [dto.toDomain()])
        XCTAssertEqual(newer, [dto.toDomain()])
        let calls = await remote.calls
        let saved = await local.saved
        XCTAssertEqual(calls, ["older:30", "newer:20"])
        XCTAssertEqual(saved, [dto.toDomain(), dto.toDomain()])
    }

    func testSaveFailureIsNotHiddenByCacheFallback() async throws {
        let dto = try makeDTO("30")
        let local = LocalStub(items: [dto.toDomain()], failsToSave: true)
        let repository = DefaultCatalogRepository(remote: RemoteStub(result: .success([dto])), local: local)
        do {
            _ = try await repository.getItems()
            XCTFail("Expected the persistence error")
        } catch Failure.diskFull {}
    }

    func testCancellationDoesNotReturnCacheAsSuccess() async throws {
        let local = LocalStub(items: [try makeDTO("30").toDomain()])
        let repository = DefaultCatalogRepository(
            remote: RemoteStub(result: .failure(CancellationError())), local: local
        )
        do {
            _ = try await repository.getItems()
            XCTFail("Expected cancellation")
        } catch is CancellationError {}
    }

    private func makeDTO(_ id: String) throws -> CatalogItemDTO {
        CatalogItemDTO(id: id, imageURL: try XCTUnwrap(URL(string: "https://example.com/photo.png")),
                       text: "Photo", confidence: 0.5)
    }
}

private enum Failure: Error { case offline, diskFull }

private actor RemoteStub: CatalogRemoteDataSource {
    let result: Result<[CatalogItemDTO], any Error>
    private(set) var calls: [String] = []
    init(result: Result<[CatalogItemDTO], any Error>) { self.result = result }
    func getItems() async throws -> [CatalogItemDTO] {
        calls.append("initial")
        return try result.get()
    }
    func getOlderItems(maxID: String) async throws -> [CatalogItemDTO] {
        calls.append("older:\(maxID)")
        return try result.get()
    }
    func getNewerItems(sinceID: String) async throws -> [CatalogItemDTO] {
        calls.append("newer:\(sinceID)")
        return try result.get()
    }
}

private actor LocalStub: CatalogLocalDataSource {
    private var items: [CatalogItem]
    private let failsToSave: Bool
    private(set) var saved: [CatalogItem] = []
    init(items: [CatalogItem] = [], failsToSave: Bool = false) {
        self.items = items
        self.failsToSave = failsToSave
    }
    func fetchItems() async throws -> [CatalogItem] { items.sorted { $0.id > $1.id } }
    func save(_ values: [CatalogItem]) async throws {
        if failsToSave { throw Failure.diskFull }
        saved += values
        for item in values {
            items.removeAll { $0.id == item.id }
            items.append(item)
        }
    }
}
