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
public typealias UnauthorizedHandler = (RestError?) -> Void

open class RestManagerConfiguration {
    private(set) var authorizationHeaderSource: AuthorisationHeaderSource = { return "" }
    private(set) var baseURL: String = ""
    private(set) var unauthorizedHandler: UnauthorizedHandler?
    private(set) var defaultHeaders: [String: String] = [:]

    public func setAuthorisationHeaderSource(_ source: @escaping AuthorisationHeaderSource) {
        self.authorizationHeaderSource = source
    }

    public func setUnauthorizedHandler(_ handler: @escaping UnauthorizedHandler) {
        self.unauthorizedHandler = handler
    }

    public func setBaseURL(_ url: String) {
        self.baseURL = url
    }

    public func setDefaultHeaders(_ headers: [String: String]) {
        self.defaultHeaders = headers
    }

    public func setDefaultHeader(header: String, value: String) {
        self.defaultHeaders[header] = value
    }
}