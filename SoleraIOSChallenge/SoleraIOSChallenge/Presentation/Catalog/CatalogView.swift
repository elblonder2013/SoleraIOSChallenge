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
            List {
                if model.isLoading && !model.items.isEmpty {
                    ProgressView("Updating catalog…")
                }
                if let error = model.errorMessage, !model.items.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(error, systemImage: "exclamationmark.circle")
                            .font(.callout)
                        Button("Try again") { Task { await model.retry() } }
                    }
                }
                ForEach(model.items) { item in
                    NavigationLink(value: item) {
                        CatalogRowView(item: item)
                    }
                    .task(id: model.isLoading) { await model.loadMoreIfNeeded(itemID: item.id) }
                }
                if model.isLoadingMore {
                    ProgressView("Loading more photos…")
                        .frame(maxWidth: .infinity)
                }
                if let error = model.paginationErrorMessage {
                    VStack(spacing: 12) {
                        Text(error).font(.callout)
                        Button("Retry loading more") {
                            Task { await model.loadMore(retry: true) }
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else if !model.hasMore && !model.items.isEmpty {
                    Text("All photos loaded")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .accessibilityIdentifier("catalog-list")
            .listStyle(.insetGrouped)
            .overlay { emptyContent }
            .refreshable { await model.refresh() }
            .navigationTitle("Catalog")
            .toolbar {
                if !model.items.isEmpty {
                    Text("\(model.items.count) photos")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("catalog-count")
                }
            }
            .navigationDestination(for: CatalogItemViewData.self) { item in
                CatalogDetailView(item: item)
            }
            .task { await model.load() }
        }
        .tint(.teal)
    }

    @ViewBuilder
    private var emptyContent: some View {
        if model.items.isEmpty {
            if model.isLoading {
                ProgressView("Loading catalog…")
                    .accessibilityIdentifier("catalog-loading")
            } else if let error = model.errorMessage {
                ContentUnavailableView {
                    Label("Couldn’t load photos", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(error)
                } actions: {
                    Button("Try again") { Task { await model.retry() } }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                ContentUnavailableView {
                    Label("No photos yet", systemImage: "photo.on.rectangle.angled")
                } description: {
                    Text("Pull down to check for new photos.")
                } actions: {
                    Button("Refresh") { Task { await model.refresh() } }
                        .buttonStyle(.bordered)
                }
            }
        }
    }
}
