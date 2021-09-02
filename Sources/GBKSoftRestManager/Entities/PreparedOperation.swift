//
//  PreparedOperation.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 24.02.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

public typealias StateCallback = (RequestState) -> Void
public typealias CompleteCallback<Model: Decodable, Response: BaseRestResponse<Model>> = (Response) -> Void
public typealias ErrorCallback<RestError> = (APIError<RestError>) -> Void where RestError: BaseRestErrorProtocol

open class PreparedOperation<Model: Decodable, Response: BaseRestResponse<Model>, RestError: BaseRestErrorProtocol> {

    private(set) var stateCallback: StateCallback?
    private(set) var completeCallback: CompleteCallback<Model, Response>?
    private(set) var errorCallback: ErrorCallback<RestError>?

    private var execute: (PreparedOperation) -> Void

    internal init(execute: @escaping (PreparedOperation) -> Void) {
        self.execute = execute
    }

    public var state: RequestState? {
        didSet {
            if let state = state {
                stateCallback?(state)
            }
        }
    }

    public var response: Response? {
        didSet {
            if let response = response {
                completeCallback?(response)
            }
        }
    }

    public var error: APIError<RestError>? {
        didSet {
            if let error = error {
                errorCallback?(error)
            }
        }
    }

    public func onStateChanged(_ stateCallback: @escaping StateCallback) -> Self {
        self.stateCallback = stateCallback
        if let state = state{
            stateCallback(state)
        }
        return self
    }

    public func onComplete(_ completeCallback: @escaping CompleteCallback<Model, Response>) -> Self {
        self.completeCallback = completeCallback
        if let response = self.response {
            completeCallback(response)
        }
        return self
    }

    public func onError(_ errorCallback: @escaping ErrorCallback<RestError>) -> Self {
        self.errorCallback = errorCallback
        if let error = self.error {
            errorCallback(error)
        }
        return self
    }

    public func run() {
        self.execute(self)
    }

}
