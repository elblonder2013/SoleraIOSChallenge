//
//  AppConfiguration.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import Foundation

struct AppConfiguration {
    let baseURL: URL
    let authorizationToken: String

    static func load(
        bundle: Bundle = .main,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> AppConfiguration {
        guard let baseURL = URL(string: "https://api.mock.marlove.net") else {
            throw ConfigurationError.invalidBaseURL
        }
        let token: String
        if let value = environment["CATALOG_API_TOKEN"], !value.isEmpty {
            token = value
        } else if let url = bundle.url(forResource: "APIConfiguration.local", withExtension: "plist") {
            token = try PropertyListDecoder().decode(Credentials.self, from: Data(contentsOf: url)).token
        } else {
            throw ConfigurationError.missingToken
        }
        guard !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ConfigurationError.missingToken
        }
        return AppConfiguration(baseURL: baseURL, authorizationToken: token)
    }

    private struct Credentials: Decodable {
        let token: String
    }

    enum ConfigurationError: LocalizedError {
        case invalidBaseURL
        case missingToken

        var errorDescription: String? {
            switch self {
            case .invalidBaseURL: "The catalog address is invalid."
            case .missingToken: "The catalog access token has not been configured."
            }
        }
    }
}
