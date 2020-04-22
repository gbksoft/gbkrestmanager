//
//  PreparedOperation.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 24.02.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

public typealias StateCallback = (RequestState) -> Void
public typealias CompleteCallback<Model: Decodable> = (Response<Model>) -> Void
public typealias ErrorCallback = (APIError) -> Void

open class PreparedOperation<Model: Decodable> {

    private(set) var stateCallback: StateCallback?
    private(set) var completeCallback: CompleteCallback<Model>?
    private(set) var errorCallback: ErrorCallback?

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

    public var response: Response<Model>? {
        didSet {
            if let response = response {
                completeCallback?(response)
            }
        }
    }

    public var error: APIError? {
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

    public func onComplete(_ completeCallback: @escaping CompleteCallback<Model>) -> Self {
        self.completeCallback = completeCallback
        if let response = self.response {
            completeCallback(response)
        }
        return self
    }

    public func onError(_ errorCallback: @escaping ErrorCallback) -> Self {
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
