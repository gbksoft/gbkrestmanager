//
//  BaseRestResponse.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 01.09.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation

open class BaseRestResponse<Model>: Decodable where Model: Decodable {
    public let result: Model?

    public init(result: Model?) {
        self.result = result
    }

    open class var empty: BaseRestResponse<Model> {
        return BaseRestResponse<Model>(result: nil)
    }
}
