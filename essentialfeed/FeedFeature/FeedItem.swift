//
//  FeedItem.swift
//  essentialfeed
//
//  Created by Max Lukashevich on 15/10/2023.
//

import Foundation

struct FeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL
}
