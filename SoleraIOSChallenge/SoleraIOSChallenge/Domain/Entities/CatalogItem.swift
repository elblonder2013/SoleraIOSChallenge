//
//  CatalogItem.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import Foundation

struct CatalogItem: Identifiable, Equatable, Sendable {
    let id: String
    let imageURL: URL
    let description: String
    let confidence: Double
}
