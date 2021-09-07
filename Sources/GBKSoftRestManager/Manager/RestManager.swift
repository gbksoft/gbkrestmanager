//
//  RestManager.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 13.02.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

open class RestManager: RestOperationsDelegate {

    public private(set) var configuration: RestManagerConfiguration = RestManagerConfiguration()
    public static let shared = RestManager()

    public init() {}

    private lazy var executor = RequestExecutor(configuration: { self.configuration })

    private var tasks: [String: [URLSessionTask]] = [:]

    public func operationsManager<T, RestError>(from operationsClass: T.Type, in context: AnyObject) -> T where T: RestOperationsManager<RestError> {
        let operations: T = operationsClass.init(contextIdentifier: String(describing: context))
        operations.delegate = self
        return operations
    }

    internal func execute<Model, Response, RestError>(model: Response.Type, errorType: RestError.Type, request: Request, identifier: String, progress: @escaping ProgressCallback, completion: @escaping RequestCompletion<Model, Response, RestError>) {

        let preCompletion: RequestCompletion<Model, Response, RestError> = { result in
            if case .failure(let error) = result,
               case .unauthorized(let errorInfo) = error {
                self.configuration.tokenRefresher { refreshed in
                    if refreshed {
                        self.execute(model: model, errorType: errorType, request: request, identifier: identifier, progress: progress, completion: completion)
                        return
                    }
                    if let handler = self.configuration.unauthorizedHandler {
                        handler(errorInfo)
                        return
                    }
                    completion(result)
                }
                return
            }
            completion(result)
        }

        let task = executor.execute(request: request, progress: progress, completion: preCompletion)

        if var existingTasks = tasks[identifier] {
            existingTasks.append(task)
            tasks[identifier] = existingTasks
        } else {
            tasks[identifier] = [task]
        }

        task.resume()
    }

    internal func cancelAllRequests(identifier: String) {
        tasks[identifier]?.forEach({$0.cancel()})
        tasks.removeValue(forKey: identifier)
    }

    deinit {
        tasks.forEach { (key, _) in
            cancelAllRequests(identifier: key)
        }
    }
}
