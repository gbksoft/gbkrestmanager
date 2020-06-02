//
//  ErrorInfo.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 28.12.2019.
//  Copyright © 2019 Artem Korzh. All rights reserved.
//

import Foundation

public struct ErrorInfo: Codable {
    public let field: String
    public let message: String
    public let code: Int
}
