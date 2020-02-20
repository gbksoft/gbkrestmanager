//
//  RestManager.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 13.02.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

class RestManager: RestOperationsDelegate {

    private(set) static var configuration: Configuration = Configuration()
    public static let shared = RestManager()

    private let executor = RequestExecutor()

    private var tasks: [String: [URLSessionTask]] = [:]

    public func operations<T: RestOperations>(from operationsClass: T.Type, in context: UIViewController) -> T {
        let operations: T = operationsClass.init(contextIdentifier: context.restIdentifier)
        operations.delegate = self
        return operations
    }

    public func operations<T: RestOperations>(from operationsClass: T.Type, in context: UIView) -> T {
        let operations: T = operationsClass.init(contextIdentifier: context.restIdentifier)
        operations.delegate = self
        return operations
    }

    internal func execute<Model>(request: Request, identifier: String, completion: @escaping RequestCompletion<Model>) {
        // request started
        let task = executor.execute(request: request) { (result) in
            // request ended
            completion(result)
        }

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
    }


}
