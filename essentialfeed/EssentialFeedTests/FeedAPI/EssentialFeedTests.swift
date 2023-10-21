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

        expect(sut, toCompleteWith: failure(.connectivity)) {
            let clientError = NSError.init(domain: "", code: 0)
            client.complete(with: clientError)
        }
    }

    func test_load_requestsDataFromURLDeliversErrorOnNon200Response() {
        let (sut, client) = makeSUT()

        let codes = [111, 201, 203, 400, 203]
        codes.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: failure(.invalidData)) {
                client.complete(withStatusCode: code, data: makeItemsJson([]), at: index)
            }
        }
    }

    func test_load_deliversErrorOn200NotValidJsonResponse() {
        let (sut, client) = makeSUT()
        let json = Data("invalid json".utf8)
        expect(sut, toCompleteWith: failure(.invalidData) ) {
            client.complete(withStatusCode: 200, data: json)
        }
    }

    func test_load_deliverEmptyListOn200HTTTPResponseWithEmptyListJson() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .success([])) {
            let json = makeItemsJson([])
            client.complete(withStatusCode: 200, data: json)
        }
    }

    func test_load_deliverItemsListOn200HTTTPResponseWithValidJson() {
        let (sut, client) = makeSUT()

        expect(sut, toCompleteWith: .success([])) {
            let json = Data("{\"items\": []}".utf8)
            client.complete(withStatusCode: 200, data: json)
        }
    }

    func test_load_deliverItemsListOn200HTTTPResponseWithJsonItems() {
        let (sut, client) = makeSUT()

        let model1 = makeFeedItem()
        let model2 = makeFeedItem()
        let model3 = makeFeedItem()

        let feedItems = [
            model1.item,
            model2.item,
            model3.item
        ]

        expect(sut, toCompleteWith: .success(feedItems)) {
            let data = self.makeItemsJson([model1.json, model2.json, model3.json])
            client.complete(withStatusCode: 200, data: data)
        }
    }

    func test_load_doesNotDeliverAnyResultIfSUTIsNil() {

        let url = URL.init(string: "http://some-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = .init(url: url, client: client)
        var capturedResults = [RemoteFeedLoader.Result]()

        sut?.load { capturedResults.append($0) }
        sut = nil

        client.complete(withStatusCode: 200, data: makeItemsJson([]))

        XCTAssert(capturedResults.isEmpty)
    }

    // MARK: Helpers

    private func makeSUT(
        url: URL = URL.init(string: "http://a.com")!,
        file: StaticString = #filePath,
        line: UInt = #line) -> (loader: RemoteFeedLoader, client: HTTPClientSpy) {
            let client = HTTPClientSpy()
            let sut = RemoteFeedLoader(url: url, client: client)

            trackForMemoryLeak(client)
            trackForMemoryLeak(sut)

            return (sut, client)
        }

    func expect(
        _ sut: RemoteFeedLoader,
        toCompleteWith expectedResult: RemoteFeedLoader.Result,
        when action: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line) {

            let exp = expectation(description: "Wait for completion")

            sut.load { result in
                switch (result, expectedResult) {
                case let (.success(item), .success(expectedItems)):
                    XCTAssertEqual(item, expectedItems, file: file, line: line)
                case let (.failure(error as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                    XCTAssertEqual(error, expectedError, file: file, line: line)
                default:
                    XCTFail("Got result: \(result), when expected result is: \(expectedResult)", file: file, line: line)
                }
                exp.fulfill()
            }

            action()
            wait(for: [exp], timeout: 1)
        }

    private func makeFeedItem(
        _ id: UUID = UUID(),
        description: String? = nil,
        location: String? = nil,
        image: String = "http://a.com") -> (item: FeedItem, json: [String: Any]) {

            let feedItem = FeedItem.init(
                id: id,
                description: description,
                location: location,
                imageURL: URL(string: image)!
            )
            let json = [
                "id": id.uuidString,
                "description": description,
                "location": location,
                "image": image
            ].reduce(into: [String: Any]()) { (acc, e) in
                if let value = e.value { acc[e.key] = value }
            }

            return (item: feedItem, json: json as [String : Any])
        }

    private func makeItemsJson(_ items: [[String: Any]]) -> Data {
        let itemsJson = ["items": items]
        return try! JSONSerialization.data(withJSONObject: itemsJson)
    }

    private func makeItem(with id: UUID, description: String? = nil, location: String? = nil, image: String) -> FeedItem {
        return .init(
            id: id,
            description: description,
            location: location,
            imageURL: URL(
                string: image
            )!
        )
    }

    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        return .failure(error)
    }
}


private class HTTPClientSpy: HTTPClient {

    private var messagesArray = [(url: URL, completion: (HTTPClientResult) -> Void)]()

    var requestedURLs: [URL] {
        return messagesArray.map({ $0.url })
    }

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void = { _ in }) {
        messagesArray.append((url, completion))
        print(messagesArray)

    }

    func complete(with error: Error, at index: Int = 0) {
        messagesArray[index].completion(.failure(error))
    }

    func complete(withStatusCode statusCode: Int, data: Data, at index: Int = 0) {
        let response = HTTPURLResponse(
            url: requestedURLs[index],
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!

        messagesArray[index].completion(.success(data, response))
    }
}
