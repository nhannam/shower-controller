//
//  BitMasks.swift
//  ShowerController
//
//  Created by Nigel Hannam on 08/11/2024.
//

import Foundation

struct ProtocolConstants {
    static let writeChunkLength = 20
    static let notificationClientSlotBase: UInt8 = 0x40
    
    static let flowRateMaximum: UInt8 = 0x64
    static let flowRateOff: UInt8 = 0x00
    
    static let uiTypeDualShower: UInt16 = 42
    static let uiTypeShowerPlusBath: UInt16 = 44
    static let uiTypeBath: UInt16 = 10001

    // Outlets
    // xxx0 = default
    // xxx1 = switched
    static let outletsSwitchedBitMask: UInt8 = 0x01

    // xx0x = lights on
    // xx1x = lights off
    static let standbyLightingDisabledBitMask: UInt8 = 0x02
    
    
    static let outlet0EnabledBitMask: UInt8 = 0x01
    static let outlet1EnabledBitMask: UInt8 = 0x02    
}
