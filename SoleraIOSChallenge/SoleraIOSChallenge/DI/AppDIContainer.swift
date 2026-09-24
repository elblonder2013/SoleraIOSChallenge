//
//  AppDIContainer.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import SwiftData

struct AppDIContainer {
    let getItems: GetCatalogItemsUseCase
    let loadMoreItems: LoadMoreCatalogItemsUseCase
    let refreshItems: RefreshCatalogItemsUseCase

    @MainActor
    func makeCatalogViewModel() -> CatalogViewModel {
        CatalogViewModel(getItems: getItems, loadMoreItems: loadMoreItems, refreshItems: refreshItems)
    }

    init(configuration: AppConfiguration) throws {
        let client = DefaultAPIClient(
            baseURL: configuration.baseURL,
            authorizationToken: configuration.authorizationToken
        )
        let remote = DefaultCatalogRemoteDataSource(client: client)
        let container = try ModelContainer(for: CatalogItemEntity.self)
        let local = DefaultCatalogLocalDataSource(modelContainer: container)
        let repository = DefaultCatalogRepository(remote: remote, local: local)
        getItems = GetCatalogItemsUseCase(repository: repository)
        loadMoreItems = LoadMoreCatalogItemsUseCase(repository: repository)
        refreshItems = RefreshCatalogItemsUseCase(repository: repository)
    }
}
