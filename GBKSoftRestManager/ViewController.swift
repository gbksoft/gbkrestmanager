//
//  ViewController.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 20.02.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

struct Order: Codable {
    let id: Int
    let title: String
}

enum DronesURL: RestURL {

    case list
    case details(id: Int)
}

class RestOrders: RestOperations {

    func list(completion: @escaping RequestCompletion<Order>) {
        let request = Request(url: <#T##RestURL#>, method: <#T##APIMethod#>, query: <#T##[String : Any]?#>, withAuthorization: <#T##Bool#>, headers: <#T##[String : String]?#>, body: <#T##Encodable?#>, media: <#T##[String : RequestMedia]?#>)
    }
}

class ViewController: UIViewController {

    lazy var operations = RestManager.shared.operations(from: RestOrders.self, in: self)

    override func viewDidLoad() {
        super.viewDidLoad()


    }

}
