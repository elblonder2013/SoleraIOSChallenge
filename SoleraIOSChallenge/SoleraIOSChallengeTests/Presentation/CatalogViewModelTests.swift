//
//  CatalogViewModelTests.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import XCTest
@testable import SoleraIOSChallenge

@MainActor
final class CatalogViewModelTests: XCTestCase {
    func testInitialState() {
        let model = makeModel(repository: CatalogRepositoryStub())
        XCTAssertTrue(model.items.isEmpty)
        XCTAssertFalse(model.isLoading)
        XCTAssertFalse(model.isLoadingMore)
        XCTAssertNil(model.errorMessage)
    }

    func testLoadMapsItemsAndDoesNotReloadCompletedRequest() async throws {
        let item = try makeItem("30")
        let repository = CatalogRepositoryStub(items: [item])
        let model = makeModel(repository: repository)
        await model.load()
        await model.load()
        XCTAssertEqual(model.items, [CatalogItemViewData(item: item)])
        XCTAssertNil(model.errorMessage)
        XCTAssertFalse(model.isLoading)
        let calls = await repository.initialCalls
        XCTAssertEqual(calls, 1)
    }

    func testFailureCanBeRetried() async throws {
        let repository = CatalogRepositoryStub(fails: true)
        let model = makeModel(repository: repository)
        await model.load()
        XCTAssertNotNil(model.errorMessage)
        XCTAssertTrue(model.items.isEmpty)
        XCTAssertFalse(model.isLoading)

        await repository.setItems([try makeItem("30")])
        await model.load()
        XCTAssertEqual(model.items.map(\.id), ["30"])
        XCTAssertNil(model.errorMessage)
    }

    func testLoadingStatePreventsConcurrentInitialRequests() async {
        let repository = CatalogRepositoryStub(suspends: true)
        let model = makeModel(repository: repository)
        let task = Task { await model.load() }
        await repository.waitUntilRequested()
        XCTAssertTrue(model.isLoading)
        await model.load()
        let calls = await repository.initialCalls
        XCTAssertEqual(calls, 1)
        await repository.resume()
        await task.value
        XCTAssertFalse(model.isLoading)
    }

    func testCancelledLoadDoesNotPublishItemsOrAnError() async throws {
        let repository = CatalogRepositoryStub(items: [try makeItem("30")], suspends: true)
        let model = makeModel(repository: repository)
        let task = Task { await model.load() }
        await repository.waitUntilRequested()
        task.cancel()
        await repository.resume()
        await task.value
        XCTAssertTrue(model.items.isEmpty)
        XCTAssertNil(model.errorMessage)
        XCTAssertFalse(model.isLoading)
    }

    private func makeItem(_ id: String) throws -> CatalogItem {
        CatalogItem(id: id, imageURL: try XCTUnwrap(URL(string: "https://example.com/image.png")),
                    description: "Photo \(id)", confidence: 0.96)
    }

    private func makeModel(repository: CatalogRepositoryStub) -> CatalogViewModel {
        CatalogViewModel(
            getItems: GetCatalogItemsUseCase(repository: repository),
            loadMoreItems: LoadMoreCatalogItemsUseCase(repository: repository),
            refreshItems: RefreshCatalogItemsUseCase(repository: repository)
        )
    }
}

private actor CatalogRepositoryStub: CatalogRepository {
    enum Failure: Error { case unavailable }
    private var items: [CatalogItem]
    private var fails: Bool
    private var suspends: Bool
    private var pending: CheckedContinuation<Void, Never>?
    private var observer: CheckedContinuation<Void, Never>?
    private(set) var initialCalls = 0

    init(items: [CatalogItem] = [], fails: Bool = false, suspends: Bool = false) {
        self.items = items
        self.fails = fails
        self.suspends = suspends
    }

    func setItems(_ items: [CatalogItem]) {
        self.items = items
        fails = false
    }

    func getItems() async throws -> [CatalogItem] {
        initialCalls += 1
        if suspends {
            await withCheckedContinuation { pending = $0; observer?.resume(); observer = nil }
        }
        if fails { throw Failure.unavailable }
        return items
    }

    func waitUntilRequested() async {
        if pending != nil { return }
        await withCheckedContinuation { observer = $0 }
    }

    func resume() {
        suspends = false
        pending?.resume()
        pending = nil
    }

    func getOlderItems(maxID: String) async throws -> [CatalogItem] { [] }
    func getNewerItems(sinceID: String) async throws -> [CatalogItem] { [] }
}
