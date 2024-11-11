//
//  Client.swift
//  ShowerController
//
//  Created by Nigel Hannam on 23/10/2024.
//

import Foundation
import SwiftData

@Model
class Client {
    @Attribute(.unique)
    var clientId: UUID
    var name: String
    var secret: Data
    
    init(clientId: UUID, name: String, secret: Data) {
        self.clientId = clientId
        self.name = name
        self.secret = secret
    }
}
