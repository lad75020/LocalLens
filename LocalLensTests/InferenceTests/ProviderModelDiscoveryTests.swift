import Foundation
import XCTest
@testable import LocalLens

final class ProviderModelDiscoveryTests: XCTestCase {
    func testOpenAICompatibleModelDiscoveryParsesModelIDs() async throws {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"object":"list","data":[{"id":"model-a"},{"id":"model-b"}]}"#.utf8))
        }
        defer { MockURLProtocol.handler = nil }
        let client = OpenAICompatibleClient(baseURL: URL(string: "http://localhost:17998/v1")!, providerID: "omlx", session: Self.session())
        let models = try await client.models()
        XCTAssertEqual(models, ["model-a", "model-b"])
    }
    private static func session() -> URLSession { let c = URLSessionConfiguration.ephemeral; c.protocolClasses = [MockURLProtocol.self]; return URLSession(configuration: c) }
}

private final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() { do { let (r,d) = try Self.handler!(request); client?.urlProtocol(self, didReceive: r, cacheStoragePolicy: .notAllowed); client?.urlProtocol(self, didLoad: d); client?.urlProtocolDidFinishLoading(self) } catch { client?.urlProtocol(self, didFailWithError: error) } }
    override func stopLoading() {}
}
