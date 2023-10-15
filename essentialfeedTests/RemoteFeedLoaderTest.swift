//
//  RemoteFeedLoaderTest.swift
//  essentialfeedTests
//
//  Created by Max Lukashevich on 15/10/2023.
//

import XCTest

class RemoteFeedLoader: FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void) {

    }
}

class HTTPClient {
    var requestedURL: URL?
}

final class RemoteFeedLoaderTest: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClient()
        XCTAssertNil(client.requestedURL, nil)
    }
}
