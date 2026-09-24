//
//  CatalogView.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import SwiftUI

struct CatalogView: View {
    @State var model: CatalogViewModel

    var body: some View {
        NavigationStack {
            Group {
                if model.isLoading && model.items.isEmpty {
                    ProgressView("Loading catalog…")
                } else if let error = model.errorMessage, model.items.isEmpty {
                    VStack(spacing: 16) {
                        Text(error)
                        Button("Try again") { Task { await model.load() } }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(model.items) { item in
                            NavigationLink(value: item) {
                                CatalogRowView(item: item)
                            }
                            .task { await model.loadMoreIfNeeded(itemID: item.id) }
                        }
                        if model.isLoadingMore {
                            ProgressView("Loading more photos…")
                                .frame(maxWidth: .infinity)
                        }
                        if let error = model.paginationErrorMessage {
                            VStack(spacing: 8) {
                                Text(error)
                                Button("Retry loading more") {
                                    Task { await model.loadMore(retry: true) }
                                }
                            }
                        } else if !model.hasMore && !model.items.isEmpty {
                            Text("All photos loaded")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Catalog")
            .navigationDestination(for: CatalogItemViewData.self) { item in
                CatalogDetailView(item: item)
            }
            .task { await model.load() }
        }
        .tint(.teal)
    }
}
