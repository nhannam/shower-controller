//
//  Converter.swift
//  ShowerController
//
//  Created by Nigel Hannam on 24/10/2024.
//

import Foundation

class Converter {
    static func celciusFromData(_ data: Data) -> Double {
        return Double(UInt16(bigEndian: data)!) * Device.temperatureSteps
    }
    
    static func celciusToData(_ celcius: Double) -> Data {
        Data(bytesFrom: UInt16((celcius / Device.temperatureSteps).rounded()).bigEndian)
    }
    
    static func secondsFromData(_ data: Data) -> Int {
        return Int(UInt16(bigEndian: data)!)
    }
    
    static func secondsFromData(_ data: UInt8) -> Int {
        return Int(data) * Device.durationSecondsSelectionSteps
    }
    
    static func secondsToData(_ seconds: Int) -> UInt8 {
        return UInt8(seconds / Device.durationSecondsSelectionSteps).bigEndian
    }
    
    private static let runningStateMappings: [UInt8: Device.RunningState] = [
        0x05: .cold,
        0x03: .paused,
        0x01: .running,
        0x00: .off
    ]
    
    static func runningStateFromData(_ data: UInt8) -> Device.RunningState {
        return runningStateMappings[data] ?? .off
    }
    
    static func runningStateToData(_ runningState: Device.RunningState) -> UInt8 {
        runningStateMappings.first(where: { data, state in runningState == state})?.key ?? 0x00
    }
    
    
    static func outletsAndButtons(_ userInterfaceType: UInt16) -> ([TechnicalInformationNotification.Valve.OutletSpec], [TechnicalInformationNotification.UI.ButtonSpec] ) {
        switch userInterfaceType {
        case ProtocolConstants.uiTypeDualShower:
            return (
                [
                    TechnicalInformationNotification.Valve.OutletSpec(outletSlot: Outlet.outletSlot0, type: .overhead),
                    TechnicalInformationNotification.Valve.OutletSpec(outletSlot: Outlet.outletSlot1, type: .handset)
                ],
                [
                    TechnicalInformationNotification.UI.ButtonSpec(
                        buttonSlot: UserInterfaceButton.buttonSlot0,
                        display: .outlet, start: .outlet,
                        outletSlot: Outlet.outletSlot0
                    ),
                    TechnicalInformationNotification.UI.ButtonSpec(
                        buttonSlot: UserInterfaceButton.buttonSlot1,
                        display: .outlet, start: .outlet,
                        outletSlot: Outlet.outletSlot1
                    )
                ]
            )
        case ProtocolConstants.uiTypeShowerPlusBath:
            return (
                [
                    TechnicalInformationNotification.Valve.OutletSpec(outletSlot: Outlet.outletSlot0, type: .overhead),
                    TechnicalInformationNotification.Valve.OutletSpec(outletSlot: Outlet.outletSlot1, type: .bath)
                ],
                [
                    TechnicalInformationNotification.UI.ButtonSpec(
                        buttonSlot: UserInterfaceButton.buttonSlot0,
                        display: .outlet, start: .outlet,
                        outletSlot: Outlet.outletSlot0
                    ),
                    TechnicalInformationNotification.UI.ButtonSpec(
                        buttonSlot: UserInterfaceButton.buttonSlot1,
                        display: .outlet, start: .preset,
                        outletSlot: Outlet.outletSlot1
                    )
                ]
            )
        case ProtocolConstants.uiTypeBath:
            return (
                [
                    TechnicalInformationNotification.Valve.OutletSpec(outletSlot: Outlet.outletSlot0, type: .bath)
                ],
                [
                    TechnicalInformationNotification.UI.ButtonSpec(
                        buttonSlot: UserInterfaceButton.buttonSlot0,
                        display: .power, start: .outlet,
                        outletSlot: Outlet.outletSlot0
                    ),
                    TechnicalInformationNotification.UI.ButtonSpec(
                        buttonSlot: UserInterfaceButton.buttonSlot1,
                        display: .outlet, start: .preset,
                        outletSlot: Outlet.outletSlot0
                    )
                ]
            )
        default:
            return (
                [
                    TechnicalInformationNotification.Valve.OutletSpec(outletSlot: Outlet.outletSlot0, type: .overhead)
                ],
                [
                    TechnicalInformationNotification.UI.ButtonSpec(
                        buttonSlot: UserInterfaceButton.buttonSlot0,
                        display: .power, start: .outlet,
                        outletSlot: Outlet.outletSlot0
                    )
                ]
            )
        }
    }
}
