//
//  Pagination.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 21.01.2020.
//  Copyright © 2020 Artem Korzh. All rights reserved.
//

import Foundation

public struct Pagination: Codable {
    public let currentPage: Int
    public let pageCount: Int
    public let perPage: Int
    public let totalCount: Int
}
