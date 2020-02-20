//
//  RestOperations.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 14.02.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

protocol RestOperationsDelegate: class {
    func execute<Model>(request: Request, identifier: String, completion: @escaping RequestCompletion<Model>)
    func cancelAllRequests(identifier: String)
}

class RestOperations {
    var delegate: RestOperationsDelegate?

    private let contextIdentifier: String
    required init(contextIdentifier: String) {
        self.contextIdentifier = contextIdentifier
    }

    public func execute<Model>(request: Request, completion: @escaping RequestCompletion<Model>) {
        delegate?.execute(request: request, identifier: contextIdentifier, completion: completion)
    }

    deinit {
        delegate?.cancelAllRequests(identifier: contextIdentifier)
    }
}
