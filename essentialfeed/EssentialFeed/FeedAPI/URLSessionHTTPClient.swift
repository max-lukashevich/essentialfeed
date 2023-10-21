//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Max Lukashevich on 21/10/2023.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {

    private struct UnexpectedValuesRepresentation: Error {}

    let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: .init(url: url)) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}
