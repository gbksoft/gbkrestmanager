# GBKSoft RestManager

Реализация базовых запросов согласно структуре API в базовом backend проекте GBKSoft

- [Requirements](#requirements)
- [Installation](#installation)
- [Overview](#overview)
- [Usage](#usage)
- [ToDo](#todo)

## Requirements 
- iOS 9.0+

## Installation
### Swift Package Manager
Перейти в `File > Swift Packages > Add Package Dependency` или перейти в проект и во вкладке `Swift Packages` нажать `+` 

Указать в поле ввода 
```
https://gitlab.gbksoft.net/gbksoft-mobile-department/ios/gbksoftrestmanager
```

### CocoaPods
В Podfile добавить
```
pod 'GBKSoftRestManager', :git => 'git@gitlab.gbksoft.net:gbksoft-mobile-department/ios/gbksoftrestmanager.git', :tag => '0.1.0'
```
и выполнить `pod install` в корне проекта 

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

// set headers validation, i.e. api version comparement
// headers: [AnyHashable: Any]
// if return false .onError handler will be called with .headerValidationFailed error
// default implementation always return true
RestManager.shared.configuration.setHeaderValidation { (headers) -> Bool in
    return true 
})
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
Разные API имеют разный формат ответа и ошибки. По умолчанию библиотека имеет реализацию ответа и ошибки для базового бекенд проекта GBK
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
Если есть необходимость работать с другим API необходимо создать собственные реализации этих сущностей. Для примера тут и далее возьмем открытое API [WeGA](https://any-api.com/weber_gesamtausgabe_de/weber_gesamtausgabe_de/console/Documents/_documents_findByAuthor_authorID_/GET)
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
Для удобства использования существуют `typealias` для использования `GBKResponse` и `GBKRestError`
```swift 
public typealias GBKPreparedOperation<Model> = PreparedOperation<Model, GBKResponse<Model>, GBKRestError> where Model: Decodable
public typealias GBKRestOperationManager = RestOperationsManager<GBKRestError>
```
Для использования прочих реализаций можно прописать собственные `typealias`. Например для WeGA
```swift 
typealias WegaRestOperationManager = RestOperationsManager<WegaError>
typealias WegaPreparedOperation<Model> = PreparedOperation<Model, WegaResponse<Model>, WegaError> where Model: Decodable
```
Примеры использования для конкретных менеджеров 
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

ошибка возвращаемая в RequestErrorHandler или onError функции 

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

### Пример использования

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

## TODO
- 
