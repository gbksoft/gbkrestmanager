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
    case png(UIImage, String?)
    case jpg(UIImage, String?)
    case mp4(URL)
    case custom(fileURL: URL, contentType: String)
    case customData(_ data: Data, fileName: String?, extension: String, contentType: String)

    var data: Data? {
        switch self {
        case .jpg(let image, _):
            return image.jpegData(compressionQuality: 1)
        case .png(let image, _):
            return image.pngData()
        case .mp4(let fileURL), .custom(let fileURL, _):
            return try? Data(contentsOf: fileURL)
        case .customData(let data, _, _, _):
            return data
        }
    }

    var contentType: String {
        switch self {
        case .jpg(_, _):
            return "image/jpeg"
        case .png(_, _):
            return "image/png"
        case .mp4(_):
            return "video/mp4"
        case .custom(_, let contentType), .customData(_, _, _, let contentType):
            return contentType
        }
    }

    var name: String {
        switch self {
        case .jpg(_, let filename):
            return filename ?? "image.jpg"
        case .png(_, let filename):
            return filename ?? "image.png"
        case .mp4(let fileURL), .custom(let fileURL, _):
            return fileURL.lastPathComponent
        case .customData(_, let fileName, let fileExtension, _):
            return "\(fileName ?? "file").\(fileExtension)"
        }
    }
}
