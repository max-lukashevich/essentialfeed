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
        sut.load()
        XCTAssertEqual(client.requestedURLs, [url])
    }

    func test_load_requestsDataFromURLTwice() {
        let url = URL.init(string: "http://some-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load()
        sut.load()

        XCTAssertEqual(client.requestedURLs, [url, url])
    }


    // MARK: Helpers

    private func makeSUT(url: URL = URL.init(string: "http://a.com")!) -> (loader: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }

    private class HTTPClientSpy: HTTPClient {
        var requestedURLs = [URL]()

        func get(from url: URL) {
            requestedURLs.append(url)
        }
    }
}
