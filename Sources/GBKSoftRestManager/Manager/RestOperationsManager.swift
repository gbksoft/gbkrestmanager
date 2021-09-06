//
//  RestOperations.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 14.02.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

protocol RestOperationsDelegate: AnyObject {
    func execute<Model, Response, RestError>(model: Response.Type, errorType: RestError.Type, request: Request, identifier: String, progress: @escaping ProgressCallback, completion: @escaping RequestCompletion<Model, Response, RestError>)
    func cancelAllRequests(identifier: String)
}

public enum RequestState {
    case started
    case ended
}

public typealias RequestExecutionHandler = (RequestState) -> Void
public typealias RequestErrorHandler<RestError> = (APIError<RestError>) -> Void where RestError: BaseRestErrorProtocol

open class RestOperationsManager<RestError: BaseRestErrorProtocol> {
    var delegate: RestOperationsDelegate?

    private let contextIdentifier: String
    private var executionHandler: RequestExecutionHandler?
    private var errorHandler: RequestErrorHandler<RestError>?

    required public init(contextIdentifier: String) {
        self.contextIdentifier = contextIdentifier
    }

    public func assignExecutionHandler(_ executionHandler: @escaping RequestExecutionHandler) {
        self.executionHandler = executionHandler
    }

    public func assignErrorHandler(_ errorHandler: @escaping RequestErrorHandler<RestError>) {
        self.errorHandler = errorHandler
    }

    public func prepare<Model, Response>(request: Request) -> PreparedOperation<Model, Response, RestError> {

        let preparedOperation = PreparedOperation<Model, Response, RestError> { [weak self] operation in
            guard let self = self else {
                return
            }
            if operation.stateCallback == nil {
                self.executionHandler?(.started)
            }
            operation.state = .started
            self.delegate?.execute(model: Response.self, errorType: RestError.self, request: request, identifier: self.contextIdentifier, progress: { uploadProgress in
                operation.uploadProgress = uploadProgress
            }, completion: { result in
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
            })
        }

        return preparedOperation
    }

    deinit {
        delegate?.cancelAllRequests(identifier: contextIdentifier)
    }
}
