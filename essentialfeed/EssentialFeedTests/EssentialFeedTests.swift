//
//  EssentialFeedTests.swift
//  EssentialFeedTests
//
//  Created by Max Lukashevich on 15/10/2023.
//

import XCTest
@testable import EssentialFeed

final class RemoteFeedLoaderTest: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClientSpy()
        _ = makeSUT()

        XCTAssertNil(client.requestedURL)
    }

    func test_load_requestDataFromURL() {
        let url = URL.init(string: "http://some-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load()
        XCTAssertEqual(client.requestedURL, url)
    }

    // MARK: Helpers

    private func makeSUT(url: URL = URL.init(string: "http://a.com")!) -> (loader: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }

    private class HTTPClientSpy: HTTPClient {
        var requestedURL: URL?

        func get(from url: URL) {
            requestedURL = url
        }
    }
}
