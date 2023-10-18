//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Max Lukashevich on 15/10/2023.
//

import Foundation

final public class RemoteFeedLoader: FeedLoader {
    private let url: URL
    private let client: HTTPClient

    public typealias Result = LoadFeedResult

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url, completion: { [weak self] response in
            guard self != nil else {
                return
            }
            switch response {
            case let .success(data, response):
                completion(FeedItemsMapper.map(data, from: response))
            case .failure:
                completion(.failure(Error.connectivity))
            }
        })
    }
}
