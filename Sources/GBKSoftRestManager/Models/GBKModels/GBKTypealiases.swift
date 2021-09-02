//
//  GBKTypealiases.swift
//  GBKSoftRestManager
//
//  Created by Artem Korzh on 02.09.2021.
//  Copyright © 2021 GBKSoft. All rights reserved.
//

import Foundation

public typealias GBKPreparedOperation<Model> = PreparedOperation<Model, GBKResponse<Model>, GBKRestError> where Model: Decodable
public typealias GBKRestOperationManager = RestOperationsManager<GBKRestError>
