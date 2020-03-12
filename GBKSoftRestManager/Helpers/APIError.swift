//
//  APIError.swift
//  Aquiline Drones
//
//  Created by Artem Korzh on 24.12.2019.
//  Copyright © 2019 Artem Korzh. All rights reserved.
//

import Foundation

public enum APIError: Error {

    case unauthorized
    case executionError(error: Error)
    case wrongResponseFormat
    case emptyResponse
    case serverError(code: Int)
    case processingError(code: Int, info: [ErrorInfo])

}
