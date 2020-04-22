//
//  Request.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 24.12.2019.
//  Copyright © 2019 Artem Korzh. All rights reserved.
//

import UIKit

public enum APIMethod: String {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
    case put = "PUT"
    case patch = "PATCH"
}

public struct Request {
    public let url: Endpoint
    public let method: APIMethod
    public var query: [String: Any]?
    public var withAuthorization: Bool = false
    public var headers: [String: String]?
    public var body: Encodable?
    public var media: [String: RequestMedia]?

    public init(url: Endpoint,
                method: APIMethod,
                query: [String: Any]? = nil,
                withAuthorization: Bool = false,
                headers: [String: String]? = nil,
        body: Encodable? = nil,
        media: [String: RequestMedia]? = nil
                ) {
        self.url = url
        self.method = method
        self.query = query
        self.withAuthorization = withAuthorization
        self.headers = headers
        self.body = body
        self.media = media
    }

    internal func finalURL(baseURL: String) -> URL {
        return url.path(baseURL: baseURL, query: query)
    }
}

public enum RequestMedia {
    case png(UIImage)
    case jpg(UIImage)
    case mp4(URL)
    case custom(fileURL: URL, contentType: String)

    var data: Data? {
        switch self {
        case .jpg(let image):
            return image.jpegData(compressionQuality: 100)
        case .png(let image):
            return image.pngData()
        case .mp4(let fileURL), .custom(let fileURL, _):
            return try? Data(contentsOf: fileURL)
        }
    }

    var contentType: String {
        switch self {
        case .jpg(_):
            return "image/jpeg"
        case .png(_):
            return "image/png"
        case .mp4(_):
            return "video/mp4"
        case .custom(_, let contentType):
            return contentType
        }
    }
}
