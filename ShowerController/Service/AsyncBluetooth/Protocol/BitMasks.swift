//
//  BitMasks.swift
//  ShowerController
//
//  Created by Nigel Hannam on 08/11/2024.
//

import Foundation

struct BitMasks {
    // xx0x = lights on
    // xx1x = lights off
    static let standbyLightingDisabled: UInt8 = 0x02
    
    // Outlets
    // xxx0 = default
    // xxx1 = switched
    static let outletsSwitched: UInt8 = 0x01
    
    
    static let outlet0Enabled: UInt8 = 0x01
    static let outlet1Enabled: UInt8 = 0x02
    
    static let maximumFlowRate: UInt8 = 0x64
}
