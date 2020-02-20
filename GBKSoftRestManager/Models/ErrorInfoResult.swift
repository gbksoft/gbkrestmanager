//
//  ErrorInfo.swift
//  Aquiline Drones
//
//  Created by Artem Korzh on 28.12.2019.
//  Copyright © 2019 Artem Korzh. All rights reserved.
//

import Foundation

struct ErrorInfoResult: Codable {
    let result: [ErrorInfo]
}

struct ErrorInfo: Codable {
    let field: String
    let message: String
    let code: Int
}
