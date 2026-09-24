//
//  CatalogItemDTO.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import Foundation

struct CatalogItemDTO: Decodable, Sendable {
    let id: String
    let imageURL: URL
    let text: String
    let confidence: Double

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case imageURL = "image"
        case text
        case confidence
    }
}
