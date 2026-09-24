//
//  CatalogDetailView.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import SwiftUI

struct CatalogDetailView: View {
    let item: CatalogItemViewData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                CatalogImageView(url: item.imageURL)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: 420)
                    .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 20) {
                    Text(item.description)
                        .font(.title2.bold())
                    field("ID", value: item.id)
                    field("Confidence", value: item.confidenceText)
                    field("Image URL", value: item.imageURL.absoluteString)
                }
                .textSelection(.enabled)
            }
            .padding(24)
            .frame(maxWidth: 800)
            .frame(maxWidth: .infinity)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Photo details")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("catalog-detail")
    }

    private func field(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
