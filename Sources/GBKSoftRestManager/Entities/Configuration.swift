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
public typealias UnauthorizedHandler = (Any?) -> Void
public typealias HeaderValidation = ([AnyHashable: Any]) -> Bool
public typealias TokenRefresher = (@escaping (Bool) -> Void) -> Void

open class RestManagerConfiguration {
    private(set) var authorizationHeaderSource: AuthorisationHeaderSource = { return "" }
    private(set) var baseURL: String = ""
    private(set) var unauthorizedHandler: UnauthorizedHandler?
    private(set) var defaultHeaders: [String: String] = [:]
    private(set) var headerValidation: HeaderValidation = {_ in true }
    private(set) var tokenRefresher: TokenRefresher = { $0(false) }

    public func setAuthorisationHeaderSource(_ source: @escaping AuthorisationHeaderSource) {
        self.authorizationHeaderSource = source
    }

    public func setUnauthorizedHandler<RestError: BaseRestErrorProtocol>(_ handler: @escaping (RestError?) -> Void) {
        self.unauthorizedHandler = { errorInfo in
            handler(errorInfo as? RestError)
        }
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

    public func setHeaderValidation(_ validation: @escaping HeaderValidation) {
        self.headerValidation = validation
    }

    public func setTokenRefresher(_ tokenRefresher: @escaping TokenRefresher) {
        self.tokenRefresher = tokenRefresher
    }
}
