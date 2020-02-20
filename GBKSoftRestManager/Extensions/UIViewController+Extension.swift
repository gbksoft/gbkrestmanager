//
//  UIViewController+Extension.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 20.02.2020.
//  Copyright © 2020 GBKSoft. All rights reserved.
//

import UIKit

extension UIViewController {

    internal var restIdentifier: String {
        return NSStringFromClass(self.classForCoder).components(separatedBy: ".").last!
    }
}
