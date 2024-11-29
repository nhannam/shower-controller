//
//  UserInterface.swift
//  ShowerController
//
//  Created by Nigel Hannam on 29/11/2024.
//

import Foundation
import SwiftData

@Model
class UserInterface {
    #Unique<UserInterface>([\.device])

    var device: Device?
    
    // 42 = dual shower, 44 = shower+bath
    var type: UInt16
    var softwareVersion: UInt16
    
    var buttons: [UserInterfaceButton]
    
    init(device: Device? = nil, type: UInt16, softwareVersion: UInt16, buttons: [UserInterfaceButton]) {
        self.device = device
        self.type = type
        self.softwareVersion = softwareVersion
        self.buttons = buttons
    }
}
