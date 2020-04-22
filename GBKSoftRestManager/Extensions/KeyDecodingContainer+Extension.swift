//
//  KeyDecodingContainer+Extension.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 28.12.2019.
//  Copyright © 2019 Artem Korzh. All rights reserved.
//

import Foundation

extension KeyedDecodingContainer {
    public func decode<T: Decodable>(_ key: Key, as type: T.Type = T.self) throws -> T {
        return try self.decode(T.self, forKey: key)
    }
}
