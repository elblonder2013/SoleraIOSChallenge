//
//  NetworkError.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case missingAuthorization
    case invalidResponse
    case httpStatus(Int)
    case transport(URLError)
    case decoding(DecodingError)
}
