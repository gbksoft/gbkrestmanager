//
//  APIError.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 24.12.2019.
//  Copyright © 2019 Artem Korzh. All rights reserved.
//

import Foundation

public enum APIError<RestError>: Error where RestError: BaseRestErrorProtocol {
    case unauthorized(error: RestError?)
    case executionError(error: Error)
    case wrongResponseFormat
    case emptyResponse
    case serverError(statusCode: Int, error: RestError?)
    case processingError(statusCode: Int, error: RestError?)
    case headerValidationFailed
}
