//
//  Request.swift
//  Aquiline Drones
//
//  Created by Artem Korzh on 24.12.2019.
//  Copyright © 2019 Artem Korzh. All rights reserved.
//

import UIKit

enum APIMethod: String {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
    case put = "PUT"
    case patch = "PATCH"
}

struct Request {
    let url: RestURL
    let method: APIMethod
    var query: [String: Any]?
    var withAuthorization: Bool = false
    var headers: [String: String]?
    var body: Encodable?
    var media: [String: RequestMedia]?

    internal var finalURL: URL {
        return url.path(baseURL: RestManager.configuration.baseURL, query: query)
    }
}

enum RequestMedia {
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
