//
//  CatalogItemEntity.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import Foundation
import SwiftData

@Model
final class CatalogItemEntity {
    @Attribute(.unique) var id: String
    var imageURL: URL
    var text: String
    var confidence: Double

    init(item: CatalogItem) {
        id = item.id
        imageURL = item.imageURL
        text = item.description
        confidence = item.confidence
    }

    func update(with item: CatalogItem) {
        imageURL = item.imageURL
        text = item.description
        confidence = item.confidence
    }

    func toDomain() -> CatalogItem {
        CatalogItem(id: id, imageURL: imageURL, description: text, confidence: confidence)
    }
}
