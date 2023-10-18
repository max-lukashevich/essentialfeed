//
//  URLSessionHTTPRequestsTests.swift
//  EssentialFeedTests
//
//  Created by Max Lukashevich on 18/10/2023.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    let session: URLSession

    internal init(session: URLSession) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping (HTTPClientResponse?) -> Void) {
        session.dataTask(with: .init(url: url)) { _, _, error in
            if let error = error {
                completion(.failure(error))
            }
        }.resume()
    }
}

final class URLSessionHTTPRequestsTests: XCTestCase {

    override class func setUp() {
        URLProtocolStub.startRequestsIntercepting()
    }

    override class func tearDown() {
        URLProtocolStub.stopRequestsIntercepting()
    }

    func test_load_didDeliversErrorOnGet() {
        let url = URL(string: "http://some-url.com")!
        let expectedError = NSError(domain: "some", code: 123)
        URLProtocolStub.stub(with: url, error: expectedError)

        let sut = URLSessionHTTPClient(session: .shared)

        let exp = expectation(description: "Wait for completion")

        sut.get(from: url) { response in
            switch response {
            case .failure(let error):
                XCTAssertEqual((error as NSError).domain, expectedError.domain)
                XCTAssertEqual((error as NSError).code, expectedError.code)
            default:
                fatalError("Expected \(expectedError) got \(String(describing: response))")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1)
    }

    // MARK - Helpers

    class URLProtocolStub: URLProtocol {

        static var subs = [URL: Stub]()

        struct Stub {
            let response: URLResponse?
            let data: Data?
            let error: Error?
        }

        static func startRequestsIntercepting() {
            URLProtocol.registerClass(self)
        }

        static func stopRequestsIntercepting() {
            URLProtocol.unregisterClass(self)
        }

        static func stub(with url: URL, response: URLResponse? = nil, data: Data? = nil, error: Error? = nil) {
            let stub = Stub(response: response, data: data, error: error)
            URLProtocolStub.subs[url] = stub
        }

        override class func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else {
                return false
            }
            return URLProtocolStub.subs[url] != nil
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            guard let url = request.url, let stub = URLProtocolStub.subs[url] else { return }

            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }

        override func stopLoading() {
            URLProtocolStub.subs = [:]
        }
    }

}
