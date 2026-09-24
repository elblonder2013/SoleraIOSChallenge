//
//  CatalogImageView.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import SwiftUI

struct CatalogImageView: View {
    let url: URL

    private var displayURL: URL {
        // The challenge's placeholder service returns SVG unless a format is requested.
        if url.host == "placehold.co", url.pathExtension.isEmpty,
           url.path.split(separator: "/").count == 1,
           var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.path += "/png"
            return components.url ?? url
        }
        return url
    }

    var body: some View {
        AsyncImage(url: displayURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFit()
            case .failure:
                placeholder(symbol: "photo.badge.exclamationmark", label: "Image unavailable")
            default:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel("Catalog photo")
    }

    private func placeholder(symbol: String, label: String) -> some View {
        Image(systemName: symbol)
            .font(.title)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(label)
    }
}
