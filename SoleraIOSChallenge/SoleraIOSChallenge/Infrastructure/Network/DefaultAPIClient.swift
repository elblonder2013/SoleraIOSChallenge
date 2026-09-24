//
//  DefaultAPIClient.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import Foundation

struct DefaultAPIClient: APIClient {
    private let baseURL: URL
    private let authorizationToken: String
    private let session: URLSession

    init(baseURL: URL, authorizationToken: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.authorizationToken = authorizationToken
        self.session = session
    }

    func request<Response: Decodable & Sendable>(_ endpoint: Endpoint) async throws -> Response {
        let request = try makeRequest(endpoint)
        try Task.checkCancellation()

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            if error.code == .cancelled { throw CancellationError() }
            throw NetworkError.transport(error)
        }

        try Task.checkCancellation()
        guard let response = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw NetworkError.httpStatus(response.statusCode)
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch let error as DecodingError {
            throw NetworkError.decoding(error)
        }
    }

    func makeRequest(_ endpoint: Endpoint) throws -> URLRequest {
        guard !authorizationToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NetworkError.missingAuthorization
        }
        guard ["https", "http"].contains(baseURL.scheme?.lowercased() ?? ""),
              baseURL.host != nil,
              var components = URLComponents(
                url: baseURL.appendingPathComponent(endpoint.path),
                resolvingAgainstBaseURL: false
              ) else {
            throw NetworkError.invalidURL
        }
        if !endpoint.queryItems.isEmpty {
            components.queryItems = (components.queryItems ?? []) + endpoint.queryItems
        }
        guard let url = components.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url, timeoutInterval: 30)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        for (name, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: name)
        }
        request.setValue(authorizationToken, forHTTPHeaderField: "Authorization")
        return request
    }
}
