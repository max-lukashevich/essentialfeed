//
//  URLSessionHTTPRequestsTests.swift
//  EssentialFeedTests
//
//  Created by Max Lukashevich on 18/10/2023.
//

import XCTest
import EssentialFeed

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
        let receivedError = resultErrorFor(data: nil, response: nil, error: expectedError)
        XCTAssertEqual((receivedError as? NSError)?.domain, expectedError.domain)
        XCTAssertEqual((receivedError as? NSError)?.code, expectedError.code)
    }

    func test_load_didDeliversErrorOnAllInvalidCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyNotHTTPResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyNotHTTPResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyNotHTTPResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPResponse(), error: anyNSError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyNotHTTPResponse(), error: nil))
    }

    func test_load_succeedsOnEmptyDataAndHTTPResponse() {
        let expectedResponse = anyHTTPResponse()
        let receivedResult = resultValueFor(data: nil, response: expectedResponse)

        let emptyData = Data()
        XCTAssertEqual(receivedResult?.data, emptyData)
        XCTAssertEqual(receivedResult?.response.url, expectedResponse.url)
        XCTAssertEqual(receivedResult?.response.statusCode, expectedResponse.statusCode)
    }

    func test_load_didDeliversSuccessResponse() {
        let expectedData = anyData()
        let expectedResponse = anyHTTPResponse()
        let response = resultValueFor(data: expectedData, response: expectedResponse)
        XCTAssertEqual(response?.data, expectedData)
        XCTAssertEqual(response?.response.url, expectedResponse.url)
        XCTAssertEqual(response?.response.statusCode, expectedResponse.statusCode)
    }

    // MARK - Helpers

    private func anyData() -> Data {
        return Data()
    }

    private func anyNSError() -> NSError {
        return NSError(domain: "domain", code: 1)
    }

    private func anyNotHTTPResponse() -> URLResponse {
        return .init(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }

    private func anyHTTPResponse() -> HTTPURLResponse {
        return .init(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }

    private func resultErrorFor(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Error? {
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        switch result {
        case .failure(let error):
            return error
        default:
            XCTFail("Expected error but got \(String(describing: response))", file: file, line: line)
            return nil
        }
    }

    private func resultValueFor(
        data: Data?,
        response: URLResponse?,
        error: Error? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (data: Data?, response: HTTPURLResponse)? {
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        switch result {
        case .success(let data, let response):
            return (data, response)
        default:
            XCTFail("Expected success response but got \(String(describing: response))", file: file, line: line)
            return nil
        }
    }

    private func resultFor(
        data: Data?,
        response: URLResponse?,
        error: Error? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) -> HTTPClientResult {
        let url = anyURL()
        URLProtocolStub.stub(with: url, response: response, error: error)

        let exp = expectation(description: "Wait for completion")

        var receivedResult: HTTPClientResult!
        makeSUT(file: file, line: line).get(from: url) { result in
            receivedResult = result
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }


    private func anyURL() -> URL {
        return URL(string: "http://some-url.com")!
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
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
