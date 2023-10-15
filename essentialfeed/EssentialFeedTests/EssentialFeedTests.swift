//
//  RemoteFeedLoaderTest.swift
//  RemoteFeedLoaderTest
//
//  Created by Max Lukashevich on 15/10/2023.
//

import XCTest
@testable import EssentialFeed

final class RemoteFeedLoaderTest: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        _ = makeSUT ()

        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_requestsDataFromURL() {
        let url = URL.init(string: "http://some-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load { _ in }
        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_load_requestsDataFromURLTwice() {
        let url = URL.init(string: "http://some-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load { _ in }     
        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url, url])
    }

    func test_load_requestsDataFromURLDeliversError() {
        let (sut, client) = makeSUT()
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }

        let clientError = NSError.init(domain: "", code: 0)
        client.complete(with: clientError)
        XCTAssertEqual(capturedErrors, [.connectivity])
    }

    func test_load_requestsDataFromURLDeliversErrorOnNon200Response() {
        let (sut, client) = makeSUT()

        let codes = [111, 201, 203, 400, 203]
        codes.enumerated().forEach { index, code in
            var capturedErrors = [RemoteFeedLoader.Error]()
            sut.load { capturedErrors.append($0) }
            client.complete(withStatusCode: code, at: index)
            XCTAssertEqual(capturedErrors, [.invalidData])
            capturedErrors = []
        }
    }


    // MARK: Helpers

    private func makeSUT(url: URL = URL.init(string: "http://a.com")!) -> (loader: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }

    private class HTTPClientSpy: HTTPClient {

        private var messagesArray = [(url: URL, completion: (HTTPClientResponse) -> Void)]()

        var requestedURLs: [URL] {
            return messagesArray.map({ $0.url })
        }

        func get(from url: URL, completion: @escaping (HTTPClientResponse) -> Void = { _ in }) {
            messagesArray.append((url, completion))
        }
        func complete(with error: Error, at index: Int = 0) {
            messagesArray[index].completion(.failure(error))
        }

        func complete(withStatusCode statusCode: Int, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!

            messagesArray[index].completion(.success(response))
        }
    }
}

/*
 - delivers error on client error

 */
