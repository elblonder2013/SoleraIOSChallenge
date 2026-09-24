//
//  CatalogRowView.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import SwiftUI

struct CatalogRowView: View {
    let item: CatalogItemViewData

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            CatalogImageView(url: item.imageURL)
                .frame(width: 88, height: 88)
            VStack(alignment: .leading, spacing: 8) {
                Text(item.description)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("ID: \(item.id)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                Text("Confidence: \(item.confidenceText)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.teal)
                Text(item.imageURL.absoluteString)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("catalog-item-\(item.id)")
    }
}
