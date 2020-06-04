//
//  SuccessResult.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 29.12.2019.
//  Copyright © 2019 Artem Korzh. All rights reserved.
//

import Foundation

public enum Status: String, Codable {
    case success
    case error
}

public struct Response<Model>: Decodable where Model: Decodable {
    public let code: Int
    public let status: Status
    public let message: String?
    public let result: Model?
    public let pagination: Pagination?

    private enum CodingKeys: String, CodingKey {
        case code, status, message
        case result
        case meta = "_meta"
        case pagination
    }

    init(result: Model?, pagination: Pagination?) {
        self.result = result
        self.pagination = pagination
        self.code = 0
        self.status = .success
        self.message = nil
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        result = try container.decode(.result)
        pagination = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .meta).decode(.pagination)
        code = try container.decode(.code)
        status = try container.decode(.status)
        message = try? container.decode(.message)
    }

    static var empty: Response<Model> {
        return Response<Model>(result: Optional<Model>.none, pagination: Optional<Pagination>.none)
    }
}
