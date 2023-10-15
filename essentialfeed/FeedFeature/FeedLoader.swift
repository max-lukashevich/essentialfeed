//
//  FeedLoader.swift
//  essentialfeed
//
//  Created by Max Lukashevich on 15/10/2023.
//

import Foundation


enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
