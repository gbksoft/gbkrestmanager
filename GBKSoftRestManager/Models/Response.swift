//
//  SuccessResult.swift
//  Aquiline Drones
//
//  Created by Artem Korzh on 29.12.2019.
//  Copyright © 2019 Artem Korzh. All rights reserved.
//

import Foundation

public struct Response<Model>: Decodable where Model: Decodable {
    public let result: Model?
    public let pagination: Pagination?

    private enum CodingKeys: String, CodingKey {
        case result
        case meta = "_meta"
        case pagination
    }

    init(result: Model?, pagination: Pagination?) {
        self.result = result
        self.pagination = pagination
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        result = try container.decode(.result)
        pagination = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .meta).decode(.pagination)
    }

    static var empty: Response<Empty> {
        return Response<Empty>(result: Optional<Empty>.none, pagination: Optional<Pagination>.none)
    }
}
