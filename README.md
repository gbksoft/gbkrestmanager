
# GBKSoft RestManager

GBKSoftRestManager is an HTTP networking library written in Swift.

- [Requirements](#requirements)
- [Installation](#installation)
- [Overview](#overview)
- [Usage](#usage)
- [ToDo](#todo)

## Requirements 
- iOS 9.0+

## Installation
### Swift Package Manager
Open `File > Swift Packages > Add Package Dependency` or navigate to project  `Swift Packages`  tab and press `+` 

Enter in field below 
```
https://gitlab.gbksoft.net/gbksoft-mobile-department/ios/gbksoftrestmanager
```

### CocoaPods
Add next line to Podfile:
```
pod 'GBKSoftRestManager', :git => 'git@gitlab.gbksoft.net:gbksoft-mobile-department/ios/gbksoftrestmanager.git', :tag => '0.1.1'
```
and run in project root directory 
```bash
$ pod install
```

## Overview 

The library is designed to execute typical REST requests used in the GBKSoft team. It allows make `GET`, `POST`, `PATCH`, `PUT`, `DELETE` requests and support JSON data and/or files

## Usage
All examples below require `import GBKSoftRestManager` somewhere in the source file.

### Global configuration

```swift
// set base url for a whole project
RestManager.shared.configuration.setBaseURL("http://your.api.provider/api/v1") 

// return any string that will be used as value for Authorization header
RestManager.shared.configuration.setAuthorisationHeaderSource { () -> String in
    // get token from storage/ 
    return "Bearer \(token)" 
}

// set global handler for 401 error
RestManager.shared.configuration.setUnauthorizedHandler { (error) in
    print(error) // error is RestError
    // TODO: logout user
}

// set default headers for all requests
// except Accept and Content-Type that will be set automatically 
RestManager.shared.configuration.setDefaultHeaders([
    "Accept-Language": "en"
])

// update/set one default header for all requests
// except Accept and Content-Type that will be set automatically 
RestManager.shared.configuration.setDefaultHeader(header: "Accept-Language", value: "en")

// set headers validation, e.g. api version comparement
// headers: [AnyHashable: Any]
// if return false .onError handler will be called with .headerValidationFailed error
// default implementation always return true
RestManager.shared.configuration.setHeaderValidation { (headers) -> Bool in
    return true 
})
```
### Main entities

#### Endpoint

For generating final request URL library uses class `Endpoint`, which takes relative path in constructor. 
It's assumed that you've provided baseURL as shown above

```swift
enum APIUser {
    static let login = Endpoint("user/login")
    static let profile = Endpoint("user/profile")
    static let avatar = Endpoint("user/photo")
}
```

#### APIMethod 

```swift
enum APIMethod: String {
    case get = "GET"
    case post = "POST"
    case delete = "DELETE"
    case put = "PUT"
    case patch = "PATCH"
}
```

#### RequestMedia

```swift
enum RequestMedia {
    case png(UIImage)
    case jpg(UIImage)
    case mp4(URL) // path to local file on device
    case custom(fileURL: URL, contentType: String) // content type should be provided as "*/*", e.g. "application/pdf" 
}
```

#### Request

`Request` - core entity to make requests

| Property | Type | Default value | Description |
| --- | --- | --- | --- |
| url | `Endpoint` | - | contains relative path to make request | 
| method | `APIMethod` | - | request method | 
| query | `[String: Any]` | nil | query fields, for example `["sort": "asc", "page": 1, "tags": ["low", "medium"]]` will be formatted as `?sort=asc&page=1&tags[]=low&tags[]=medium` |
| headers | `[String: String]` | nil | Additional headers for request |
| body | `Encodable` | nil | body of requests, must conform to `Encodable` to be converted in JSON string  |
| media | `[String: RequestMedia]` | nil | List of files to be sent 

#### BaseRestResponse, BaseRestErrorProtocol
```swift 
open class BaseRestResponse<Model>: Decodable where Model: Decodable {
    public let result: Model?

    public init(result: Model?) {
        self.result = result
    }

    class var empty: BaseResponse<Model> {
        return BaseResponse<Model>(result: nil)
    }
}

public  protocol  BaseRestErrorProtocol: Decodable {}
```
Different API has different  format for response and error. By default library has implementation for basic format used in GBK projects
```swift
public enum Status: String, Codable {
    case success
    case error
}

public class GBKResponse<Model>: BaseRestResponse<Model> where Model: Decodable {
    typealias Model = Model

    public let code: Int
    public let status: Status
    public let message: String?
    public let pagination: Pagination?

    private enum CodingKeys: String, CodingKey {
        case code, status, message
        case result
        case meta = "_meta"
        case pagination
    }

    init(result: Model?, pagination: Pagination?) {
        self.pagination = pagination
        self.code = 0
        self.status = .success
        self.message = nil
        super.init(result: result)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pagination = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .meta).decode(.pagination)
        code = try container.decode(.code)
        status = try container.decode(.status)
        message = try? container.decode(.message)
        let result: Model? = try container.decode(.result)
        super.init(result: result)
    }

    override class var empty: GBKResponse<Model> {
        return GBKResponse<Model>(result: Optional<Model>.none, pagination: Optional<Pagination>.none)
    }
}
```
```swift 
public struct GBKRestError: BaseRestErrorProtocol {
    public let code: Int
    public let status: Status
    public let message: String?
    public let result: [ErrorInfo]?
    public let name: String?
}
```
If it's required to use other API you have to create custom implementation for response formats that meets this API. For example hereinafter used  [WeGA](https://any-api.com/weber_gesamtausgabe_de/weber_gesamtausgabe_de/console/Documents/_documents_findByAuthor_authorID_/GET)
```swift 
class WegaResponse<Model: Decodable>: BaseRestResponse<Model> {
    required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let result: Model = try container.decode(Model.self)
        super.init(result: result)
    }
}

struct WegaError: BaseRestErrorProtocol {
    let message: String
    let code: Int
    let fields: String
}
```

#### OperationsManager

```swift

enum RequestState {
    case started
    case ended
}

public typealias RequestExecutionHandler = (RequestState) -> Void
public typealias RequestErrorHandler<RestError> = (APIError<RestError>) -> Void where RestError: BaseRestErrorProtocol

class RestOperationsManager<RestError: BaseRestErrorProtocol> { 
    func assignExecutionHandler(_ executionHandler: @escaping RequestExecutionHandler)
    func assignErrorHandler(_ errorHandler: @escaping RequestErrorHandler<RestError>)
    func prepare<Model, Response>(request: Request) -> PreparedOperation<Model, Response, RestError>
}
```
For ease of use there are few `typealias` to use in GBK projects: `GBKResponse` and `GBKRestError`
```swift 
public typealias GBKPreparedOperation<Model> = PreparedOperation<Model, GBKResponse<Model>, GBKRestError> where Model: Decodable
public typealias GBKRestOperationManager = RestOperationsManager<GBKRestError>
```
For other implementation you can add your own `typealias`. For example for WeGA
```swift 
typealias WegaRestOperationManager = RestOperationsManager<WegaError>
typealias WegaPreparedOperation<Model> = PreparedOperation<Model, WegaResponse<Model>, WegaError> where Model: Decodable
```
Use cases for specific managers 
```swift 
class RestConfigManager: GBKRestOperationManager {
    public func getConfig() -> GBKPreparedOperation<ConfigModel> {
	    let endpoint = Endpoint("v1/config")
        let request = Request(url: endpoint, method: .get)
        return prepare(request: request)
    }
}

class RestDocumentManager: WegaRestOperationManager {
    func getDocuments(authorID: String) -> WegaPreparedOperation<[DocumentModel]> {
        let endpoint = Endpoint("v1/documents/findByAuthor/\(authorID)")
        let request = Request(url: endpoint, method: .get, query: ["limit": 10])
        return prepare(request: request)
    }
}

```

#### APIError

Error cases that can be received in `RequestErrorHandler` or `onError` functions

```swift
public enum APIError<RestError>: Error where RestError: BaseRestErrorProtocol  {
    case unauthorized(error: RestError?)                        // if server returns 401 code
    case executionError(error: Error)                           // if something crashed inbetween the client app and the server
    case wrongResponseFormat                                    // if response returned by server not in json format or failed to decode into model
    case emptyResponse                                          // if no body of request returned and code is not 204
    case serverError(statusCode: Int, error: RestError?)        // if server returns 50_ code
    case processingError(statusCode: Int, error: RestError?)    // if server failed to process request data. most of time RestError will contain non empty result: [ErrorInfo] 
    case headerValidationFailed                                 // if header validation return false
}
```

### Use case

```swift
import GBKSoftRestManager
	
class RestUser: GBKRestOperationsManager {

    func login(data: LoginData) -> GBKPreparedOperation<AuthModel> {
        // simple post request with encodable structure 
        let request = Request(url: APIUser.login, method: .post, body: data)
        return prepare(request: request)
    }

    func profile() -> GBKPreparedOperation<UserModel> {
        // simple get request with authorization header
        let request = Request(url: APIUser.profile, method: .get, withAuthorization: true)
        return prepare(request: request)
    }

    func uploadAvatar(image: UIImage) -> GBKPreparedOperation<AvatarModel> {
        // post request with jpg image and authorization header
        let request = Request(
            url: APIUser.avatar, 
            method: .post, 
            withAuthorization: true, 
            media: ["file": .jpg(image)]
        )
        return prepare(request: request)
    }
}

...

lazy var userOperationsManager: RestUser = {
    let manager = RestManager.shared.operationsManager(from: RestUser.self, in: self)
    
    // global execution state handler. used for loaders. not used if local handler added
    manager.assignExecutionHandler { (state) in  
        print(state)
    }
    
    // global error handler. not used if local handler added
    manager.assignErrorHandler { (error) in  
        print(error)
    }
    return manager
}()

...

func login() {
    let data = LoginData(email: "client@ad.com", password: "A1111111") // just for example
    userOperationsManager.login(data: data)
        .onComplete { [weak self] (response) in
            if let auth = response.result {
                // set received token as auth token for future requests
                // just for example. current realisation can cause memory leaks
                RestManager.shared.configuration.setAuthorisationHeaderSource { () -> String in
                    return "Bearer \(auth.token)"
                }
                self?.getProfile()
                self?.updateAvatar()
            }
    }.run()
}

func getProfile() {
    userOperationsManager.profile()
        .onComplete { (response) in
            if let user = response.result {
                print(user)
            }
    }.run()
}

func updateAvatar() {
    let image = UIImage(systemName: "star")! // just for example
    userOperationsManager.uploadAvatar(image: image)
	    .onComplete { (response) in
	        if let avatar = response.result {
	            print(avatar)
	        }
        }.onUploadProgressChanged { (progress)
            showUploadProgress(progress)
	    }.onStateChanged { (state) in        // local state handler. e.g. to toggle loading indicator
	        switch state {
	        case .started:
	            loader.show()
	        case .ended:
	            loader.hide()
	        }
	    }.onError({ (error) in                   // local error handler 
	        print(error)
	    }).run()
}
```

## TODO
- 
