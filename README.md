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
RestManager.shared.configuration.setBaseURL("http://your.api.provider/api/v1") // set base url for a whole project

RestManager.shared.configuration.setAuthorisationHeaderSource { () -> String in
    // get token from storage/ 
    return "Bearer \(token)" // return any string that will be used as value for Authorization header
}
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
    case mp4(URL)
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

#### Response

```swift
struct Response<Model>: Decodable where Model: Decodable {
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
            let request = Request(url: APIUser.avatar, method: .post, withAuthorization: true, media: ["file": .jpg(image)])
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
                    RestManager.configuration.setAuthorisationHeaderSource { () -> String in
                        return "Bearer \(auth.token)"
                    }
                    self?.getProfile()
                    self?.updateAvatar()
                }
        }.execute()
    }
    
    func getProfile() {
        userOperationsManager.profile()
            .onComplete { (response) in
                if let user = response.result {
                    print(user)
                }
        }.execute()
    }

    func updateAvatar() {
        let image = UIImage(systemName: "star")!
        userOperationsManager.uploadAvatar(image: image)
            .onComplete { (response) in
                if let avatar = response.result {
                    print(avatar)
                }
        }.onStart { // local state handler 
            print("upload started")
        }.onEnd { // local state handler 
            print("upload ended")
        }.onError({ (error) in // local error handler 
            print(error)
        }).execute()
    }
```


