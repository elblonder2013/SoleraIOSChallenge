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
    private(set) var errorMessage: String?

    private let getItems: GetCatalogItemsUseCase
    private let loadMoreItems: LoadMoreCatalogItemsUseCase
    private let refreshItems: RefreshCatalogItemsUseCase
    private var hasLoaded = false

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
            let result = try await getItems.execute()
            try Task.checkCancellation()
            items = result.map(CatalogItemViewData.init)
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            errorMessage = "Couldn’t load the catalog. Please try again."
        }
    }
}
