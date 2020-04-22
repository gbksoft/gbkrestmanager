//
//  RestError.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 17.04.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

public struct RestError: Codable {
    public let code: Int
    public let status: Status
    public let message: String?
    public let result: [ErrorInfo]?
    public let name: String?
}
