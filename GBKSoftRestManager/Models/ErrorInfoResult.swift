//
//  ErrorInfo.swift
//  Aquiline Drones
//
//  Created by Artem Korzh on 28.12.2019.
//  Copyright © 2019 Artem Korzh. All rights reserved.
//

import Foundation

public struct ErrorInfoResult: Codable {
    let result: [ErrorInfo]
}

public struct ErrorInfo: Codable {
    let field: String
    let message: String
    let code: Int
}
