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

    internal init(session: URLSession = .shared) {
        self.session = session
    }

    func get(from url: URL, completion: @escaping (HTTPClientResponse?) -> Void) {
        session.dataTask(with: .init(url: url)) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            }
        }.resume()
    }
}

final class URLSessionHTTPRequestsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        URLProtocolStub.startRequestsIntercepting()
    }

    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopRequestsIntercepting()
    }

    func test_getFromURL_performGETMethodWithURL() {

        let url = anyURL()
        let exp = expectation(description: "Wait for completion")

        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(url, request.url)
            XCTAssertEqual("GET", request.httpMethod)
            exp.fulfill()
        }

        makeSUT().get(from: url, completion: { _ in })

        wait(for: [exp], timeout: 1.0)
    }

    func test_load_didDeliversErrorOnGet() {
        
        let expectedError = NSError(domain: "some", code: 123)
        let url = anyURL()
        URLProtocolStub.stub(with: url, error: expectedError)

        let exp = expectation(description: "Wait for completion")

        makeSUT().get(from: url) { response in
            switch response {
            case .failure(let error):
                XCTAssertEqual((error as NSError).domain, expectedError.domain)
                XCTAssertEqual((error as NSError).code, expectedError.code)
            default:
                XCTFail("Expected \(expectedError) got \(String(describing: response))")
            }
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    // MARK - Helpers

    private func anyURL() -> URL {
        return URL(string: "http://some-error-url.com")!
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeak(sut, file: file, line: line)
        return sut
    }

    class URLProtocolStub: URLProtocol {

        private static var stub: Stub?
        private static var requestObserver: ((URLRequest) -> Void)?

        struct Stub {
            let response: URLResponse?
            let data: Data?
            let error: Error?
        }

        static func startRequestsIntercepting() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }

        static func stopRequestsIntercepting() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }

        static func observeRequest(with completion: @escaping (URLRequest) -> Void) {
            requestObserver = completion
        }

        static func stub(with url: URL, response: URLResponse? = nil, data: Data? = nil, error: Error? = nil) {
            URLProtocolStub.stub = Stub(response: response, data: data, error: error)
        }

        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }

        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }

        override func startLoading() {
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {
        }
    }

}
