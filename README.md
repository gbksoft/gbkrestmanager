# GBKSoft RestManager

Реализация базовых запросов согласно структуре API в базовом backend проекте GBKSoft

## Requirements 
- iOS 9.0+

## Installation 

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate GBKSoftRestManager into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'GBKSoftRestManager', :git => 'git@gitlab.gbksoft.net:korzh-aa/gbksoftrestmanager.git'
end
```

Then, run the following command:

```bash
$ pod install
```

## Overview 

Библиотека предназначена для выполнения типичных REST запросов, используемых в команде GBKSoft. 
Позволяет делать `GET`, `POST`, `PATCH`, `PUT`, `DELETE` запросы с отправкой данных в формате JSON и/или файлов

## Usage

### Подключение библиотеки 

```swift
import GBKSoftRestManager
```

### Глобальная настройка

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
```
### Основные классы 

#### Endpoints

Библиотека использует для формирования URL класс `Endpoint`, который в конструкторе принимает относительный путь 

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
    case custom(fileURL: URL, contentType: String) // content type should be provided as "*/*", i.e. "application/pdf" 
}
```

#### Request

`Request` - базовый класс для формирования запросов 

| Поле | Тип | Значение по умолчанию | Описание |
| --- | --- | --- | --- |
| url | `Endpoint` | - | относительный путь для запроса | 
| method | `APIMethod` | - | метод запроса | 
| query | `[String: Any]` | nil | данные для query части запроса. пример: `["sort": "asc", "page": 1, "tags": ["low", "medium"]]` в результате трансформируются в `?sort=asc&page=1&tags[]=low&tags[]=medium` |
| headers | `[String: String]` | nil | Дополнительные headers для запроса |
| body | `Encodable` | nil | тело запроса, может принимать любое значение соответсвующее протоколу `Encodable`, обьект класса или структуры, массив, сет, словарь и тд.  |
| media | `[String: RequestMedia]` | nil | 

#### OperationsManager

```swift

enum RequestState {
    case started
    case ended
}

public typealias RequestExecutionHandler = (RequestState) -> Void
public typealias RequestErrorHandler = (APIError) -> Void

class RestOperationsManager { 
    func assignExecutionHandler(_ executionHandler: @escaping RequestExecutionHandler)
    func assignErrorHandler(_ errorHandler: @escaping RequestErrorHandler)
    func prepare<Model>(request: Request) -> PreparedOperation<Model>
}
```



#### APIError

ошибка возвращаемая в RequestErrorHandler или onError функции 

```swift
public enum APIError: Error {
    case unauthorized(error: RestError?)                        // if server returns 401 code
    case executionError(error: Error)                           // if something crashed inbetween the client app and the server
    case wrongResponseFormat                                    // if response returned by server not in json format or failed to decode into model
    case emptyResponse                                          // if no body of request returned and code is not 204
    case serverError(statusCode: Int, error: RestError?)        // if server returns 50_ code
    case processingError(statusCode: Int, error: RestError?)    // if server failed to process request data. most of time RestError will contain non empty result: [ErrorInfo] 
}
```

#### RestError

```swift
public struct RestError: Codable {
    public let code: Int
    public let status: Status       // .success or .error 
    public let message: String?
    public let result: [ErrorInfo]? 
    public let name: String?
}

public struct ErrorInfo: Codable {
    let field: String   // field failed validation
    let message: String // validation error
    let code: Int       // validation error code
}
```

#### Response

```swift
struct Response<Model>: Decodable where Model: Decodable {
    public let code: Int
    public let status: Status           // .success or .error
    public let message: String?
    public let result: Model?
    public let pagination: Pagination?
}
```

### Использование в коде 

```swift
    
    class RestUser: RestOperationsManager {

        func login(data: LoginData) -> PreparedOperation<AuthModel> {
            // simple post request with encodable structure 
            let request = Request(url: APIUser.login, method: .post, body: data)
            return prepare(request: request)
        }

        func profile() -> PreparedOperation<UserModel> {
            // simple get request with authorization header
            let request = Request(url: APIUser.profile, method: .get, withAuthorization: true)
            return prepare(request: request)
        }

        func uploadAvatar(image: UIImage) -> PreparedOperation<AvatarModel> {
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
        }.onStateChanged { (state) in        // local state handler. i.e. to toggle loading indicator
            switch state {
            case .started:
                loader.show()
            case .ended:
                loader.hide()
            }
        }.onEnd {                                // local state handler 
            updateUserAvatar()
        }.onError({ (error) in                   // local error handler 
            print(error)
        }).run()
    }
```


