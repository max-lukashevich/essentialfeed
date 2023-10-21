//
//  EssentialFeedAPIEndToEndTests.swift
//  EssentialFeedAPIEndToEndTests
//
//  Created by Max Lukashevich on 21/10/2023.
//

import XCTest
import EssentialFeed


final class EssentialFeedAPIEndToEndTests: XCTestCase {

    func test_endToEndTestServerGETFeedResult_matchesFixedTestAccountData() {
       
        switch getFeedResult() {
        case .success(let array):
            XCTAssertTrue(array.count == 8)

            XCTAssertEqual(array[0], expectedItem(at: 0))
            XCTAssertEqual(array[1], expectedItem(at: 1))
            XCTAssertEqual(array[2], expectedItem(at: 2))
            XCTAssertEqual(array[3], expectedItem(at: 3))
            XCTAssertEqual(array[4], expectedItem(at: 4))
            XCTAssertEqual(array[5], expectedItem(at: 5))
            XCTAssertEqual(array[6], expectedItem(at: 6))
            XCTAssertEqual(array[7], expectedItem(at: 7))

        case .failure(let error):
            XCTFail("Expected to get result, got an error \(error) instead")
        case nil:
            XCTFail("Expected to get result, got an no result instead")
        }
    }

    // MARK: Helpers

    func getFeedResult(file: StaticString = #filePath, line: UInt = #line) -> LoadFeedResult? {
        let url = URL(string: "http://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient()
        let sut = RemoteFeedLoader(url: url, client: URLSessionHTTPClient())


        trackForMemoryLeak(client, file: file, line: line)
        trackForMemoryLeak(sut, file: file, line: line)

        let exp = expectation(description: "Waiting for result")

        var expectedResult: LoadFeedResult?

        sut.load { result in
            expectedResult = result
            exp.fulfill()
        }

        wait(for: [exp], timeout: 5.0)
        return expectedResult
    }

    private func expectedItem(at index: Int) -> FeedItem {
        return .init(
            id: expectedId(at: index),
            description: expectedDescription(at: index),
            location: expectedLocation(at: index),
            imageURL: expectedImage(at: index)
        )
    }

    private func expectedId(at index: Int) -> UUID {
        let jsonData = [
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "BA298A85-6275-48D3-8315-9C8F7C1CD109",
            "5A0D45B3-8E26-4385-8C5D-213E160A5E3C",
            "FF0ECFE2-2879-403F-8DBE-A83B4010B340",
            "DC97EF5E-2CC9-4905-A8AD-3C351C311001",
            "557D87F1-25D3-4D77-82E9-364B2ED9CB30",
            "A83284EF-C2DF-415D-AB73-2A9B8B04950B",
            "F79BD7F8-063F-46E2-8147-A67635C3BB01"
        ]
        guard index >= 0 && index < jsonData.count, let uuid = UUID(uuidString: jsonData[index]) else {
            fatalError("Invalid index or UUID conversion.")
        }
        return uuid
    }

    private func expectedDescription(at index: Int) -> String? {
        let jsonData = [
            "Description 1",
            nil,
            "Description 3",
            nil,
            "Description 5",
            "Description 6",
            "Description 7",
            "Description 8"
        ]
        guard index >= 0 && index < jsonData.count else {
            fatalError("Invalid index.")
        }
        return jsonData[index]
    }

    private func expectedLocation(at index: Int) -> String? {
        let jsonData = [
            "Location 1",
            "Location 2",
            nil,
            nil,
            "Location 5",
            "Location 6",
            "Location 7",
            "Location 8"
        ]
        guard index >= 0 && index < jsonData.count else {
            fatalError("Invalid index.")
        }
        return jsonData[index]
    }

    private func expectedImage(at index: Int) -> URL {
        let jsonData = [
            "https://url-1.com",
            "https://url-2.com",
            "https://url-3.com",
            "https://url-4.com",
            "https://url-5.com",
            "https://url-6.com",
            "https://url-7.com",
            "https://url-8.com"
        ]
        guard index >= 0 && index < jsonData.count, let url = URL(string: jsonData[index]) else {
            fatalError("Invalid index or URL conversion.")
        }
        return url
    }
}
