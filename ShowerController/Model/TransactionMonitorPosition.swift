//
//  TransactionMonitorPosition.swift
//  ShowerController
//
//  Created by Nigel Hannam on 23/10/2024.
//

import Foundation
import SwiftData

@Model
class TransactionMonitorPosition {
    var token: DefaultHistoryToken

    init(token: DefaultHistoryToken) {
        self.token = token
    }
}
