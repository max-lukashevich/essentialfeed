//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Max Lukashevich on 17/10/2023.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
