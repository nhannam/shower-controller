//
//  UserInterfaceButton.swift
//  ShowerController
//
//  Created by Nigel Hannam on 29/11/2024.
//

import Foundation
import SwiftData

@Model
class UserInterfaceButton {
    enum ButtonDisplayBehaviour: String, Codable {
        case outlet, power
    }
    enum ButtonStartBehaviour: String, Codable {
        case outlet, preset
    }
    
    static let buttonSlot0 = 0
    static let buttonSlot1 = 1

    #Unique<UserInterfaceButton>([\.userInterface, \.buttonSlot])

    var userInterface: UserInterface?
    var buttonSlot: Int
    
    var display: ButtonDisplayBehaviour
    var start: ButtonStartBehaviour
    var outlet: Outlet
    
    init(userInterface: UserInterface? = nil, buttonSlot: Int, display: ButtonDisplayBehaviour, start: ButtonStartBehaviour, outlet: Outlet) {
        self.userInterface = userInterface
        self.buttonSlot = buttonSlot
        self.display = display
        self.start = start
        self.outlet = outlet
    }
}
