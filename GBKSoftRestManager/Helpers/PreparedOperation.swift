//
//  PreparedOperation.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 24.02.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import Foundation

public typealias Callback = () -> Void
public typealias CompleteCallback<Model: Decodable> = (Response<Model>) -> Void
public typealias ErrorCallback = (APIError) -> Void

open class PreparedOperation<Model: Decodable> {

    private(set) var startCallback: Callback?
    private(set) var endCallback: Callback?
    private(set) var completeCallback: CompleteCallback<Model>?
    private(set) var errorCallback: ErrorCallback?

    private var run: (PreparedOperation) -> Void

    internal init(run: @escaping (PreparedOperation) -> Void) {
        self.run = run
    }

    public var state: RequestState = .started {
        didSet {
            switch state {
            case .started:
                startCallback?()
            case .ended:
                endCallback?()
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

    public func onStart(_ startCallback: @escaping Callback) -> Self {
        self.startCallback = startCallback
        if self.state == .started {
            startCallback()
        }
        return self
    }

    public func onEnd(_ endCallback: @escaping Callback) -> Self {
        self.endCallback = endCallback
        if self.state == .ended {
            endCallback()
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

    public func execute() {
        self.run(self)
    }

}
