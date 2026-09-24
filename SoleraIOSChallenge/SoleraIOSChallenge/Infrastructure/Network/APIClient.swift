//
//  APIClient.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

protocol APIClient: Sendable {
    func request<Response: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> Response
}
