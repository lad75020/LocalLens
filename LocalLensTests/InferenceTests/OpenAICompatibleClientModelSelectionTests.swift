import Foundation
import XCTest
@testable import LocalLens

final class OpenAICompatibleClientModelSelectionTests: XCTestCase {
    func testEmbeddingsRequestUsesSelectedModelID() async throws {
        nonisolated(unsafe) var body = ""
        ModelSelectionURLProtocol.handler = { request in
            body = requestBodyString(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"data":[{"index":0,"embedding":[0.1,0.2]}]}"#.utf8))
        }
        defer { ModelSelectionURLProtocol.handler = nil }
        let config = URLSessionConfiguration.ephemeral; config.protocolClasses = [ModelSelectionURLProtocol.self]
        let client = OpenAICompatibleClient(baseURL: URL(string: "http://localhost:11434/v1")!, providerID: "ollama", session: URLSession(configuration: config))
        _ = try await client.embeddings(model: "selected-model", inputs: ["hello"])
        XCTAssertTrue(body.contains("selected-model"))
    }
}

private final class ModelSelectionURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() { do { let (r,d) = try Self.handler!(request); client?.urlProtocol(self, didReceive: r, cacheStoragePolicy: .notAllowed); client?.urlProtocol(self, didLoad: d); client?.urlProtocolDidFinishLoading(self) } catch { client?.urlProtocol(self, didFailWithError: error) } }
    override func stopLoading() {}
}


private func requestBodyString(_ request: URLRequest) -> String {
    if let body = request.httpBody { return String(data: body, encoding: .utf8) ?? "" }
    guard let stream = request.httpBodyStream else { return "" }
    stream.open()
    defer { stream.close() }
    var data = Data()
    var buffer = [UInt8](repeating: 0, count: 4096)
    while stream.hasBytesAvailable {
        let read = stream.read(&buffer, maxLength: buffer.count)
        if read <= 0 { break }
        data.append(buffer, count: read)
    }
    return String(data: data, encoding: .utf8) ?? ""
}
