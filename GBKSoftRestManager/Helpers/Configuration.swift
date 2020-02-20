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

typealias ExecutionStateHandler = (ExecutingState) -> Void
typealias AuthorisationHeaderSource = () -> String

struct Configuration {
    private(set) var authorizationHeaderSource: AuthorisationHeaderSource = { return "" }
    private(set) var baseURL: String = ""

    mutating func setAuthorisationHeaderSource(_ source: @escaping AuthorisationHeaderSource) {
        self.authorizationHeaderSource = source
    }

    mutating func setBaseURL(_ url: String) {
        self.baseURL = url
    }
}
