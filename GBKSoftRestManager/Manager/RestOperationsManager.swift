//
//  RestOperations.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 14.02.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

protocol RestOperationsDelegate: class {
    func execute<Model>(model: Model.Type, request: Request, identifier: String, completion: @escaping RequestCompletion<Model>)
    func cancelAllRequests(identifier: String)
}

public enum RequestState {
    case started
    case ended
}

public typealias RequestExecutionHandler = (RequestState) -> Void
public typealias RequestErrorHandler = (APIError) -> Void

open class RestOperationsManager {
    var delegate: RestOperationsDelegate?

    private let contextIdentifier: String
    private var executionHandler: RequestExecutionHandler?
    private var errorHandler: RequestErrorHandler?

    required public init(contextIdentifier: String) {
        self.contextIdentifier = contextIdentifier
    }

    public func assignExecutionHandler(_ executionHandler: @escaping RequestExecutionHandler) {
        self.executionHandler = executionHandler
    }

    public func assignErrorHandler(_ errorHandler: @escaping RequestErrorHandler) {
        self.errorHandler = errorHandler
    }

    public func prepare<Model>(request: Request) -> PreparedOperation<Model> {

        let preparedOperation = PreparedOperation<Model> { [weak self] operation in
            guard let self = self else {
                return
            }
            if operation.stateCallback == nil {
                self.executionHandler?(.started)
            }
            operation.state = .started
            self.delegate?.execute(model: Model.self, request: request, identifier: self.contextIdentifier) { (result) in
                switch result {
                case .success(let response) :
                    operation.response = response
                case .failure(let error):
                    if operation.errorCallback == nil {
                        self.errorHandler?(error)
                    }
                    operation.error = error
                }
                if operation.stateCallback == nil {
                    self.executionHandler?(.ended)
                }
                operation.state = .ended
            }
        }

        return preparedOperation
    }

    deinit {
        delegate?.cancelAllRequests(identifier: contextIdentifier)
    }
}
