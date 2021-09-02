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

public class GBKResponse<Model>: BaseRestResponse<Model> where Model: Decodable {

    typealias Model = Model

    public let code: Int
    public let status: Status
    public let message: String?
    public let pagination: Pagination?

    private enum CodingKeys: String, CodingKey {
        case code, status, message
        case result
        case meta = "_meta"
        case pagination
    }

    init(result: Model?, pagination: Pagination?) {
        self.pagination = pagination
        self.code = 0
        self.status = .success
        self.message = nil
        super.init(result: result)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pagination = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .meta).decode(.pagination)
        code = try container.decode(.code)
        status = try container.decode(.status)
        message = try? container.decode(.message)
        let result: Model? = try container.decode(.result)
        super.init(result: result)
    }

    public override class var empty: GBKResponse<Model> {
        return GBKResponse<Model>(result: Optional<Model>.none, pagination: Optional<Pagination>.none)
    }
}
