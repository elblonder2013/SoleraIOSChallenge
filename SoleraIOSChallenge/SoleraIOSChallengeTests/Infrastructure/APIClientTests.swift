//
//  APIClientTests.swift
//  SoleraIOSChallenge
//
//  Created by Alexei on 24/09/2026.
//

import XCTest
@testable import SoleraIOSChallenge

@MainActor
final class APIClientTests: XCTestCase {
    func testRequestIncludesPathQueryHeadersAndRawAuthorization() throws {
        let client = try makeClient()
        let request = try client.makeRequest(Endpoint(
            path: "v1/items",
            queryItems: [URLQueryItem(name: "max_id", value: "id /?&=30")],
            headers: ["X-Request-ID": "request-1", "Authorization": "overridden"]
        ))

        let url = try XCTUnwrap(request.url)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        XCTAssertEqual(url.path, "/v1/items")
        XCTAssertEqual(components.queryItems, [URLQueryItem(name: "max_id", value: "id /?&=30")])
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "test-token")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Request-ID"), "request-1")
    }

    func testMissingTokenFailsBeforeMakingARequest() throws {
        let client = try makeClient(token: " \n ")
        XCTAssertThrowsError(try client.makeRequest(Endpoint(path: "v1/items"))) { error in
            guard case NetworkError.missingAuthorization = error else {
                return XCTFail("Expected missing authorization, got \(error)")
            }
        }
    }

    func testInvalidBaseURLIsRejected() throws {
        let client = DefaultAPIClient(
            baseURL: URL(fileURLWithPath: "/tmp/catalog"), authorizationToken: "test-token"
        )
        XCTAssertThrowsError(try client.makeRequest(Endpoint(path: "items"))) { error in
            guard case NetworkError.invalidURL = error else {
                return XCTFail("Expected invalid URL, got \(error)")
            }
        }
    }

    func testSuccessfulResponseIsDecoded() async throws {
        let client = try makeClient()
        let result: Payload = try await client.request(Endpoint(path: "success"))
        XCTAssertEqual(result.value, "hello")
    }

    func testHTTPErrorPreservesStatusCode() async throws {
        let client = try makeClient()
        do {
            let _: Payload = try await client.request(Endpoint(path: "unauthorized"))
            XCTFail("Expected an HTTP error")
        } catch NetworkError.httpStatus(let status) {
            XCTAssertEqual(status, 401)
        }
    }

    func testMalformedJSONReportsDecodingError() async throws {
        let client = try makeClient()
        do {
            let _: Payload = try await client.request(Endpoint(path: "malformed"))
            XCTFail("Expected a decoding error")
        } catch NetworkError.decoding {
            // The server response was successful, but its body was not valid JSON.
        }
    }

    func testTransportFailurePreservesURLError() async throws {
        let client = try makeClient()
        do {
            let _: Payload = try await client.request(Endpoint(path: "offline"))
            XCTFail("Expected a transport error")
        } catch NetworkError.transport(let error) {
            XCTAssertEqual(error.code, .notConnectedToInternet)
        }
    }

    func testCancellationIsNotReportedAsNetworkFailure() async throws {
        let client = try makeClient()
        do {
            let _: Payload = try await client.request(Endpoint(path: "cancelled"))
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Cancellation lets callers leave the current UI state alone.
        }
    }

    func testNonHTTPResponseIsRejected() async throws {
        let client = try makeClient()
        do {
            let _: Payload = try await client.request(Endpoint(path: "non-http"))
            XCTFail("Expected an invalid response")
        } catch NetworkError.invalidResponse {
            // Only HTTP responses carry a status code we can validate.
        }
    }

    private func makeClient(token: String = "test-token") throws -> DefaultAPIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        addTeardownBlock { session.invalidateAndCancel() }
        return DefaultAPIClient(
            baseURL: try XCTUnwrap(URL(string: "https://example.com")),
            authorizationToken: token,
            session: session
        )
    }
}

private struct Payload: Decodable, Sendable {
    let value: String
}

private final class StubURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        if url.path == "/offline" || url.path == "/cancelled" {
            let code: URLError.Code = url.path == "/offline" ? .notConnectedToInternet : .cancelled
            client?.urlProtocol(self, didFailWithError: URLError(code))
            return
        }

        let response: URLResponse
        if url.path == "/non-http" {
            response = URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        } else {
            guard let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: url.path == "/unauthorized" ? 401 : 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            ) else {
                client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
                return
            }
            response = httpResponse
        }
        let body = url.path == "/malformed" ? "not JSON" : #"{"value":"hello"}"#
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
