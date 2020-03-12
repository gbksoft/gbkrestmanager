//
//  Pagination.swift
//  Aquiline Drones
//
//  Created by Artem Korzh on 21.01.2020.
//  Copyright © 2020 Artem Korzh. All rights reserved.
//

import Foundation

public struct Pagination: Codable {
    let currentPage: Int
    let pageCount: Int
    let perPage: Int
    let totalCount: Int
}
