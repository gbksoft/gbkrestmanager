//
//  RequestExecutor.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 24.12.2019.
//  Copyright © 2019 Artem Korzh. All rights reserved.
//

import Foundation

typealias RequestCompletion<Model, Response, RestError> = (Result<Response, APIError<RestError>>) -> Void
    where Model: Decodable, Response: BaseRestResponse<Model>, RestError: BaseRestErrorProtocol

class RequestExecutor {

    public var currentConfiguration: () -> RestManagerConfiguration

    init(configuration: @escaping () -> RestManagerConfiguration) {
        self.currentConfiguration = configuration
    }

    private let urlSession = URLSession(configuration: .default)

    func execute<Model, Response, RestError>(request: Request, completion: @escaping RequestCompletion<Model, Response, RestError>) -> URLSessionTask {
        if request.media != nil {
            return uploadTask(request: request, completion: completion)
        } else {
            return defaultTask(request: request, completion: completion)
        }

    }

    private func defaultTask<Model, Response, RestError>(request: Request, completion: @escaping RequestCompletion<Model, Response, RestError>) -> URLSessionTask {
        var urlRequest = URLRequest(url: request.finalURL(baseURL: currentConfiguration().baseURL))
        urlRequest.httpMethod = request.method.rawValue
        let customHeaders =  currentConfiguration().defaultHeaders
            .merging(request.headers ?? [:], uniquingKeysWith: {(_, new) in new})
        customHeaders.forEach({ urlRequest.setValue($1, forHTTPHeaderField: $0) })
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        if request.withAuthorization {
            urlRequest.setValue(getAuthHeader(), forHTTPHeaderField: "Authorization")
        }
        urlRequest.httpBody = request.body?.json

        let task = urlSession.dataTask(with: urlRequest) { (data, response, error) in
            DispatchQueue.global().async {
                self.printResponse(request: request, urlRequest: urlRequest, data: data, response: response, error: error)
            }
            let headers: [AnyHashable: Any] = (response as? HTTPURLResponse)?.allHeaderFields ?? [:]
            guard self.currentConfiguration().headerValidation(headers) else {
                completion(.failure(.headerValidationFailed))
                return
            }
            DispatchQueue.main.async {
                self.processResponse(data: data, response: response, error: error, completion: completion)
            }
        }
        return task
    }

    private func uploadTask<Model, Response, RestError>(request: Request, completion: @escaping RequestCompletion<Model, Response, RestError>) -> URLSessionTask {
        var urlRequest = URLRequest(url: request.finalURL(baseURL: currentConfiguration().baseURL))
        urlRequest.httpMethod = request.method.rawValue
        let customHeaders =  currentConfiguration().defaultHeaders
            .merging(request.headers ?? [:], uniquingKeysWith: {(_, new) in new})
        customHeaders.forEach({ urlRequest.setValue($1, forHTTPHeaderField: $0) })
        let boundary = "Boundary-\(UUID().uuidString)"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        if request.withAuthorization {
            urlRequest.setValue(getAuthHeader(), forHTTPHeaderField: "Authorization")
        }
        var body = Data()
        if let data = request.body?.dictionary {
            for (key, value) in data {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }
        }

        if let media = request.media {
            for (key, file) in media {
                guard let data = file.data else {
                    continue
                }
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(file.name)\"\r\n")
                body.append("Content-Type: \(file.contentType)\r\n\r\n")
                body.append(data)
                body.append("\r\n")
            }
        }

        body.append("--\(boundary)--\r\n")

        let task = urlSession.uploadTask(with: urlRequest, from: body) { (data, response, error) in
            DispatchQueue.global().async {
                self.printResponse(request: request, urlRequest: urlRequest, data: data, response: response, error: error)
            }
            DispatchQueue.main.async {
                self.processResponse(data: data, response: response, error: error, completion: completion)
            }
        }
        return task
    }

    private func processResponse<Model, Response, RestError>(data: Data?, response: URLResponse?, error: Error?, completion: RequestCompletion<Model, Response, RestError>) where Model: Decodable, Response: BaseRestResponse<Model> {

        if let error = error {
            completion(.failure(.executionError(error: error)))
            return
        }
        if let httpResponse = response as? HTTPURLResponse {
            var errorInfo: RestError?
            if let data = data,
                let info = try? JSONDecoder().decode(RestError.self, from: data) {
                errorInfo = info
            }
            switch httpResponse.statusCode {
            case 204:
                if Model.self == Empty.self {
                    let result = Response.empty
                    completion(.success(result as! Response))
                    return
                }
            case 401:
                completion(.failure(.unauthorized(error: errorInfo)))
                return
            case 400, 402..<500:
                completion(.failure(.processingError(statusCode: httpResponse.statusCode, error: errorInfo)))
                return
            case 500..<600:
                completion(.failure(.serverError(statusCode: httpResponse.statusCode, error: errorInfo)))
                return
            default:
                break
            }
        }

        guard let data = data else {
            completion(.failure(.emptyResponse))
            return
        }

        do {
            let response = try JSONDecoder().decode(Response.self, from: data)
            completion(.success(response))
        } catch let error {
            debugPrint(error)
            completion(.failure(.wrongResponseFormat))
        }
    }

    private func getAuthHeader() -> String {
        return currentConfiguration().authorizationHeaderSource()
    }

    private func printResponse(request: Request, urlRequest: URLRequest, data: Data?, response: URLResponse?, error: Error?) {
        debugPrint("=====================REQUEST=====================")
        debugPrint("Method: \(urlRequest.httpMethod ?? "<undefined>")")
        debugPrint("URL: \(urlRequest.url?.absoluteString ?? "<undefined>")")
        debugPrint("Headers:", urlRequest.allHTTPHeaderFields ?? "<empty>")
        if let sentData = request.body?.json,
            let sentJSON = try? JSONSerialization.jsonObject(with: sentData, options: []) {
            debugPrint("Body:", sentJSON)
        } else {
            debugPrint("Body:", "<empty>")
        }
        debugPrint("====================RESPONSE=====================")
        if let httpResponse = response as? HTTPURLResponse {
            debugPrint("Status code: \(httpResponse.statusCode)")
            debugPrint("Headers:", httpResponse.allHeaderFields)
        } else {
            debugPrint("Status code: <undefined>")
            debugPrint("Headers: <undefined>")
        }
        if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) {
            debugPrint("Response JSON:", json)
        } else if let data = data, let responseText = String(data: data, encoding: String.Encoding.utf8) {
            debugPrint("Response Text:", responseText)
        } else {
            debugPrint("Response: <empty>")
        }
        if let error = error {
            debugPrint("Error occured: ", error.localizedDescription)
        }
        debugPrint("================================================")
    }

}
