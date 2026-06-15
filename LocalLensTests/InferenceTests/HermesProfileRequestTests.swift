import Foundation
import XCTest
@testable import LocalLens

final class HermesProfileRequestTests: XCTestCase {
    func testHermesProfileHeaderIsSentWithoutChangingModel() async throws {
        nonisolated(unsafe) var header: String?
        nonisolated(unsafe) var body = ""
        HermesRequestURLProtocol.handler = { request in
            header = request.value(forHTTPHeaderField: "X-Hermes-Profile")
            body = requestBodyString(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(#"{"choices":[{"message":{"content":"{}"}}]}"#.utf8))
        }
        defer { HermesRequestURLProtocol.handler = nil }
        let c = URLSessionConfiguration.ephemeral; c.protocolClasses = [HermesRequestURLProtocol.self]
        let client = OpenAICompatibleClient(baseURL: URL(string: "http://localhost:8642/v1")!, providerID: "hermes-agent", session: URLSession(configuration: c))
        _ = try await client.chatJSON(model: "hermes-agent", payload: "{}", hermesProfileID: "office")
        XCTAssertEqual(header, "office")
        XCTAssertTrue(body.contains("hermes-agent"))
        XCTAssertFalse(body.contains("office\""))
    }
}

private final class HermesRequestURLProtocol: URLProtocol {
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
