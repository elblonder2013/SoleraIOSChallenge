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

    func testPaginationAppendsUniqueItemsAndStopsAtBoundaryOnlyPage() async throws {
        let repository = CatalogRepositoryStub(items: [try makeItem("30"), try makeItem("30"), try makeItem("29")])
        let model = makeModel(repository: repository)
        await model.load()
        await repository.setOlderItems([try makeItem("29"), try makeItem("28"), try makeItem("28")])
        await model.loadMoreIfNeeded(itemID: "29")
        XCTAssertEqual(model.items.map(\.id), ["30", "29", "28"])
        await repository.setOlderItems([try makeItem("28")])
        await model.loadMoreIfNeeded(itemID: "28")
        await model.loadMoreIfNeeded(itemID: "28")
        XCTAssertFalse(model.hasMore)
        let calls = await repository.olderCalls
        XCTAssertEqual(calls, ["29", "28"])
    }

    func testPaginationDoesNotReplaceContentOrMakeConcurrentRequests() async throws {
        let repository = CatalogRepositoryStub(items: [try makeItem("30")])
        let model = makeModel(repository: repository)
        await model.load()
        await repository.suspendNextRequest()
        let task = Task { await model.loadMoreIfNeeded(itemID: "30") }
        await repository.waitUntilRequested()
        XCTAssertTrue(model.isLoadingMore)
        XCTAssertFalse(model.isLoading)
        XCTAssertEqual(model.items.map(\.id), ["30"])
        await model.loadMoreIfNeeded(itemID: "30")
        let calls = await repository.olderCalls
        XCTAssertEqual(calls, ["30"])
        await repository.resume()
        await task.value
    }

    func testPaginationFailureNeedsExplicitRetryAndPreservesContent() async throws {
        let repository = CatalogRepositoryStub(items: [try makeItem("30")])
        let model = makeModel(repository: repository)
        await model.load()
        await repository.setFailure(true)
        await model.loadMore()
        await model.loadMore()
        XCTAssertNotNil(model.paginationErrorMessage)
        XCTAssertEqual(model.items.map(\.id), ["30"])
        var calls = await repository.olderCalls
        XCTAssertEqual(calls, ["30"])
        await repository.setFailure(false)
        await repository.setOlderItems([try makeItem("29")])
        await model.loadMore(retry: true)
        calls = await repository.olderCalls
        XCTAssertEqual(calls, ["30", "30"])
        XCTAssertEqual(model.items.map(\.id), ["30", "29"])
        XCTAssertNil(model.paginationErrorMessage)
    }

    func testRefreshPrependsNewItemsWithoutDuplicates() async throws {
        let repository = CatalogRepositoryStub(items: [try makeItem("30"), try makeItem("29")])
        let model = makeModel(repository: repository)
        await model.load()
        await repository.setNewerItems([try makeItem("31"), try makeItem("30")])
        await model.refresh()
        XCTAssertEqual(model.items.map(\.id), ["31", "30", "29"])
        let calls = await repository.newerCalls
        XCTAssertEqual(calls, ["30"])
        XCTAssertFalse(model.isRefreshing)
    }

    func testRefreshFailurePreservesContent() async throws {
        let repository = CatalogRepositoryStub(items: [try makeItem("30")])
        let model = makeModel(repository: repository)
        await model.load()
        await repository.setFailure(true)
        await model.refresh()
        XCTAssertEqual(model.items.map(\.id), ["30"])
        XCTAssertNotNil(model.errorMessage)
        XCTAssertFalse(model.isRefreshing)
    }

    func testRefreshPreventsOtherRequestsWhileItIsRunning() async throws {
        let repository = CatalogRepositoryStub(items: [try makeItem("30")])
        let model = makeModel(repository: repository)
        await model.load()
        await repository.suspendNextRequest()
        let task = Task { await model.refresh() }
        await repository.waitUntilRequested()
        XCTAssertTrue(model.isRefreshing)
        await model.refresh()
        await model.loadMore()
        let calls = await repository.newerCalls
        let olderCalls = await repository.olderCalls
        XCTAssertEqual(calls, ["30"])
        XCTAssertTrue(olderCalls.isEmpty)
        await repository.resume()
        await task.value
    }

    func testCachedItemsAreVisibleBeforeRemoteRequestFinishes() async throws {
        let cached = try makeItem("29")
        let repository = CatalogRepositoryStub(items: [try makeItem("30"), cached], suspends: true)
        await repository.setCachedItems([cached])
        let model = makeModel(repository: repository)
        let task = Task { await model.load() }
        await repository.waitUntilRequested()
        XCTAssertEqual(model.items.map(\.id), ["29"])
        XCTAssertTrue(model.isLoading)
        await repository.resume()
        await task.value
        XCTAssertEqual(model.items.map(\.id), ["30", "29"])
    }

    func testBackgroundFailureKeepsCachedContentVisibleAndRetryable() async throws {
        let repository = CatalogRepositoryStub(fails: true)
        await repository.setCachedItems([try makeItem("29")])
        let model = makeModel(repository: repository)
        await model.load()
        XCTAssertEqual(model.items.map(\.id), ["29"])
        XCTAssertNotNil(model.errorMessage)
        await repository.setItems([try makeItem("30"), try makeItem("29")])
        await model.retry()
        XCTAssertEqual(model.items.map(\.id), ["30", "29"])
        XCTAssertNil(model.errorMessage)
    }

    func testEmptyCatalogCanBeRefreshed() async throws {
        let repository = CatalogRepositoryStub()
        let model = makeModel(repository: repository)
        await model.load()
        XCTAssertTrue(model.items.isEmpty)
        XCTAssertFalse(model.hasMore)
        await repository.setItems([try makeItem("30")])
        await model.refresh()
        XCTAssertEqual(model.items.map(\.id), ["30"])
        XCTAssertTrue(model.hasMore)
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
    private(set) var olderCalls: [String] = []
    private var cachedItems: [CatalogItem] = []
    private var olderItems: [CatalogItem] = []
    private var newerItems: [CatalogItem] = []
    private(set) var newerCalls: [String] = []

    init(items: [CatalogItem] = [], fails: Bool = false, suspends: Bool = false) {
        self.items = items
        self.fails = fails
        self.suspends = suspends
    }

    func setItems(_ items: [CatalogItem]) {
        self.items = items
        fails = false
    }

    func setCachedItems(_ values: [CatalogItem]) { cachedItems = values }
    func getCachedItems() async throws -> [CatalogItem] { cachedItems }

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

    func setOlderItems(_ items: [CatalogItem]) { olderItems = items }
    func setFailure(_ value: Bool) { fails = value }
    func suspendNextRequest() { suspends = true }

    func getOlderItems(maxID: String) async throws -> [CatalogItem] {
        olderCalls.append(maxID)
        if suspends {
            await withCheckedContinuation { pending = $0; observer?.resume(); observer = nil }
        }
        if fails { throw Failure.unavailable }
        return olderItems
    }
    func setNewerItems(_ items: [CatalogItem]) { newerItems = items }

    func getNewerItems(sinceID: String) async throws -> [CatalogItem] {
        newerCalls.append(sinceID)
        if suspends {
            await withCheckedContinuation { pending = $0; observer?.resume(); observer = nil }
        }
        if fails { throw Failure.unavailable }
        return newerItems
    }
}
