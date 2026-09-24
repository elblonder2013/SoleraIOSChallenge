//
//  CatalogItemViewData.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import Foundation

struct CatalogItemViewData: Identifiable, Equatable, Hashable {
    let id: String
    let imageURL: URL
    let description: String
    let confidenceText: String

    init(item: CatalogItem) {
        id = item.id
        imageURL = item.imageURL
        description = item.description
        confidenceText = item.confidence.formatted(.number.precision(.fractionLength(0...6)))
    }
}
