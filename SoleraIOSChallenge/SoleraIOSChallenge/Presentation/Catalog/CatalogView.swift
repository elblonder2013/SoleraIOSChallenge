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
                    List(model.items) { item in
                        CatalogRowView(item: item)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Catalog")
            .task { await model.load() }
        }
        .tint(.teal)
    }
}
