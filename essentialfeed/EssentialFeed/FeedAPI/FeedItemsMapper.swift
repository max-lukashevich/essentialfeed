//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Max Lukashevich on 15/10/2023.
//

import Foundation

internal final class FeedItemsMapper {

    private struct Root: Decodable {
        let items: [Item]

        var feed: [FeedItem] {
            return items.map { $0.feedItem }
        }
    }

    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: URL

        var feedItem: FeedItem {
            return .init(
                id: id,
                description: description,
                location: location,
                imageURL: image
            )
        }
    }

    internal static func map(_ data: Data, from response: HTTPURLResponse) -> RemoteFeedLoader.Result {

        guard response.statusCode == 200,
              let root = try? JSONDecoder().decode(Root.self, from: data)else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }
        return .success(root.feed)
    }
}
