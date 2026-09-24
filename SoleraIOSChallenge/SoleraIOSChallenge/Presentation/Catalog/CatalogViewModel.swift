//
//  CatalogViewModel.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import Observation

@MainActor
@Observable
final class CatalogViewModel {
    private(set) var items: [CatalogItemViewData] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var isRefreshing = false
    private(set) var errorMessage: String?
    private(set) var paginationErrorMessage: String?
    private(set) var hasMore = true

    private let getItems: GetCatalogItemsUseCase
    private let loadMoreItems: LoadMoreCatalogItemsUseCase
    private let refreshItems: RefreshCatalogItemsUseCase
    private var hasLoaded = false
    private var requestedCursor: String?

    init(
        getItems: GetCatalogItemsUseCase,
        loadMoreItems: LoadMoreCatalogItemsUseCase,
        refreshItems: RefreshCatalogItemsUseCase
    ) {
        self.getItems = getItems
        self.loadMoreItems = loadMoreItems
        self.refreshItems = refreshItems
    }

    func load() async {
        guard !isLoading, !hasLoaded else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let cached = try await getItems.cachedItems()
            try Task.checkCancellation()
            items = unique(cached.map(CatalogItemViewData.init))
        } catch is CancellationError {
            return
        } catch {
            errorMessage = "Saved photos couldn’t be read. Trying the catalog service."
        }
        do {
            let result = try await getItems.execute()
            try Task.checkCancellation()
            items = unique(result.map(CatalogItemViewData.init))
            hasMore = !items.isEmpty
            hasLoaded = true
            errorMessage = nil
        } catch is CancellationError {
            return
        } catch {
            errorMessage = "Couldn’t load the catalog. Please try again."
        }
    }

    func loadMoreIfNeeded(itemID: String) async {
        guard itemID == items.last?.id else { return }
        await loadMore()
    }

    func loadMore(retry: Bool = false) async {
        guard !isLoading, !isLoadingMore, !isRefreshing, hasMore, let cursor = items.last?.id,
              retry || cursor != requestedCursor else { return }
        requestedCursor = cursor
        isLoadingMore = true
        paginationErrorMessage = nil
        defer { isLoadingMore = false }
        do {
            let page = try await loadMoreItems.execute(maxID: cursor).map(CatalogItemViewData.init)
            try Task.checkCancellation()
            let existingIDs = Set(items.map(\.id))
            let additions = unique(page).filter { !existingIDs.contains($0.id) }
            items += additions
            hasMore = !additions.isEmpty
        } catch is CancellationError {
            requestedCursor = nil
        } catch {
            paginationErrorMessage = "Couldn’t load more photos. Please try again."
        }
    }

    func refresh() async {
        guard !isLoading, !isLoadingMore, !isRefreshing else { return }
        guard let newestID = items.first?.id else {
            hasLoaded = false
            await load()
            return
        }
        isRefreshing = true
        errorMessage = nil
        defer { isRefreshing = false }
        do {
            let page = try await refreshItems.execute(sinceID: newestID).map(CatalogItemViewData.init)
            try Task.checkCancellation()
            items = unique(page + items)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = "Couldn’t refresh the catalog. Your loaded photos are still available."
        }
    }

    private func unique(_ values: [CatalogItemViewData]) -> [CatalogItemViewData] {
        var seen = Set<String>()
        return values.filter { seen.insert($0.id).inserted }
    }
}
