//
//  Converter.swift
//  ShowerController
//
//  Created by Nigel Hannam on 24/10/2024.
//

import Foundation

class Converter {
    static func celciusFromData(_ data: Data) -> Double {
        return Double(UInt16(data[0]) << 8 | UInt16(data[1])) * Device.temperatureSteps
    }
    
    static func celciusToData(_ celcius: Double) -> Data {
        Data(bytesFrom: UInt16((celcius / Device.temperatureSteps).rounded()).bigEndian)
    }

    static func secondsFromData(_ data: Data) -> Int {
        return Int(UInt16(data[0]) << 8 | UInt16(data[1]))
    }

    static func secondsFromData(_ data: UInt8) -> Int {
        return Int(data) * Device.durationSecondsSelectionSteps
    }

    static func secondsToData(_ seconds: Int) -> UInt8 {
        return UInt8(seconds / Device.durationSecondsSelectionSteps).bigEndian
    }
    
    private static let runningStateMappings: [UInt8: RunningState] = [
        0x05: .cold,
        0x03: .paused,
        0x01: .running,
        0x00: .off
    ]
    
    static func runningStateFromData(_ data: UInt8) -> RunningState {
        return runningStateMappings[data] ?? .off
    }
    
    static func runningStateToData(_ runningState: RunningState) -> UInt8 {
        runningStateMappings.first(where: { data, state in runningState == state})?.key ?? 0x00
    }
}
