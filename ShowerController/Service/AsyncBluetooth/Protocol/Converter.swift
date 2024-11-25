//
//  Converter.swift
//  ShowerController
//
//  Created by Nigel Hannam on 24/10/2024.
//

import Foundation

class Converter {
    static func celciusFromData(_ data: UInt8) -> Double {
        return (Double(Int(256) + Int(data)) / 10).rounded()
    }
    
    static func celciusToData(_ celcius: Double) -> UInt8 {
        return UInt8(((celcius * 10) - 256).rounded())
    }

    static func secondsFromData(_ data: Data) -> Int {
        return Int(UInt16(data[0])<<8 | UInt16(data[1]))
    }

    static func secondsFromData(_ data: UInt8) -> Int {
        return Int(Int(data) * 10)
    }

    static func secondsToData(_ seconds: Int) -> UInt8 {
        return UInt8(seconds / 10)
    }
    
    static func runningStateFromData(_ data: UInt8) -> RunningState {
        switch data {
        case 0x05:
            return .cold
        case 0x03:
            return .paused
        case 0x01:
            return .running
        case 0x00:
            return .off
        default:
            // This shouldn't happen
            return .off
        }
    }
    
    static func runningStateToData(_ runningState: RunningState) -> UInt8 {
        switch runningState {
        case .cold:
            return 0x05
        case .paused:
            return 0x03
        case .running:
            return 0x01
        case .off:
            return 0x00
        }
    }

}
