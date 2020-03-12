//
//  RestManager.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 13.02.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

open class RestManager: RestOperationsDelegate {

    public private(set) static var configuration: RestManagerConfiguration = RestManagerConfiguration()
    public static let shared = RestManager()

    private let executor = RequestExecutor()

    private var tasks: [String: [URLSessionTask]] = [:]

    public func operationsManager<T: RestOperationsManager>(from operationsClass: T.Type, in context: UIViewController) -> T {
        let operations: T = operationsClass.init(contextIdentifier: context.restIdentifier)
        operations.delegate = self
        return operations
    }

    public func operationsManager<T: RestOperationsManager>(from operationsClass: T.Type, in context: UIView) -> T {
        let operations: T = operationsClass.init(contextIdentifier: context.restIdentifier)
        operations.delegate = self
        return operations
    }

    internal func execute<Model>(model: Model.Type, request: Request, identifier: String, completion: @escaping RequestCompletion<Model>) {

        let task = executor.execute(request: request, completion: completion)

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