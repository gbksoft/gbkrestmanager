//
//  Configuration.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 13.02.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

enum ExecutingState {
    case executionStarted
    case executionEnded
}

public typealias AuthorisationHeaderSource = () -> String

open class RestManagerConfiguration {
    private(set) var authorizationHeaderSource: AuthorisationHeaderSource = { return "" }
    private(set) var baseURL: String = ""

    public func setAuthorisationHeaderSource(_ source: @escaping AuthorisationHeaderSource) {
        self.authorizationHeaderSource = source
    }

    public func setBaseURL(_ url: String) {
        self.baseURL = url
    }
}
