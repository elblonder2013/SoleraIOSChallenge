//
//  AppDIContainer.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

struct AppDIContainer {
    let getItems: GetCatalogItemsUseCase
    let loadMoreItems: LoadMoreCatalogItemsUseCase
    let refreshItems: RefreshCatalogItemsUseCase

    @MainActor
    func makeCatalogViewModel() -> CatalogViewModel {
        CatalogViewModel(getItems: getItems, loadMoreItems: loadMoreItems, refreshItems: refreshItems)
    }

    init(configuration: AppConfiguration) {
        let client = DefaultAPIClient(
            baseURL: configuration.baseURL,
            authorizationToken: configuration.authorizationToken
        )
        let remote = DefaultCatalogRemoteDataSource(client: client)
        let repository = DefaultCatalogRepository(remote: remote)
        getItems = GetCatalogItemsUseCase(repository: repository)
        loadMoreItems = LoadMoreCatalogItemsUseCase(repository: repository)
        refreshItems = RefreshCatalogItemsUseCase(repository: repository)
    }
}
