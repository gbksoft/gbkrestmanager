//
//  RestURL.swift
//  Aquiline Drones
//
//  Created by Artem Korzh on 24.12.2019.
//  Copyright © 2019 Artem Korzh. All rights reserved.
//

import Foundation

enum RestURL: String {

    case root = "/"

    internal func path(baseURL: String, query: [String: Any]? = nil) -> URL {

        var path = URLComponents(string: "http://google.com")!

        if let query = query {
            path.queryItems = queryItems(from: query)
        }

        return path.url!
    }

    public func endpoint() -> String {
        return self.rawValue
    }

    private func queryItems(from query: [String: Any]) -> [URLQueryItem] {
        if query.count == 0 {
            return []
        }
        var queryItems: [URLQueryItem] = []
        query.forEach { (key, value) in
            if let array = value as? [Any] {
                queryItems.append(contentsOf: array.map({URLQueryItem(name: "\(key)[]", value: "\($0)")}))
                return
            }
            queryItems.append(URLQueryItem(name: key, value: "\(value)"))
        }
        return queryItems
    }

    private func queryString(from query: [String: Any]) -> String {
        if query.count == 0 {
            return ""
        }
        let queryString = query.map { (key, value) -> String in
            if let array = value as? [Any] {
                return array.map({"\(key)[]=\($0)"}).joined(separator: "&")
            }
            return "\(key)=\(value)"
        }.joined(separator: "&")
        return "?\(queryString)"
    }

}
