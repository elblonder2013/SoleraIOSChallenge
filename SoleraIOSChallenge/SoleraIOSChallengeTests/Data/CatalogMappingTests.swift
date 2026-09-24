//
//  CatalogMappingTests.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import XCTest
@testable import SoleraIOSChallenge

final class CatalogMappingTests: XCTestCase {
    func testAPIResponseMapsEveryFieldToDomain() throws {
        let json = #"[{"_id":"6915a62ede391","image":"https://placehold.co/512x512?text=30.%20rbgvb","text":"30. rbgvb","confidence":0.96}]"#
        let dto = try XCTUnwrap(JSONDecoder().decode([CatalogItemDTO].self, from: Data(json.utf8)).first)

        let item = dto.toDomain()

        XCTAssertEqual(item.id, "6915a62ede391")
        XCTAssertEqual(item.imageURL.absoluteString, "https://placehold.co/512x512?text=30.%20rbgvb")
        XCTAssertEqual(item.description, "30. rbgvb")
        XCTAssertEqual(item.confidence, 0.96)
    }

    func testMissingRequiredFieldFailsDecoding() {
        let json = #"[{"_id":"id","text":"Photo","confidence":0.96}]"#
        XCTAssertThrowsError(try JSONDecoder().decode([CatalogItemDTO].self, from: Data(json.utf8)))
    }
}
