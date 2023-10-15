//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Max Lukashevich on 15/10/2023.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL)
}

public class RemoteFeedLoader {
    private let client: HTTPClient
    private  let url: URL

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load( ) {
        client.get(from: url)
    }
}
