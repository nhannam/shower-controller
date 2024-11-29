//
//  DeviceNotification.swift
//  ShowerController
//
//  Created by Nigel Hannam on 26/10/2024.
//

import Foundation

protocol OutletNotification {
    func accept(_ visitor: OutletNotificationVisitor)
}

protocol PresetNotification {
    func accept(_ visitor: PresetNotificationVisitor)
}

protocol ClientNotification {
    func accept(_ visitor: ClientNotificationVisitor)
}

protocol DeviceNotification: Sendable {
    var deviceId: UUID { get }

    func accept(_ visitor: DeviceNotificationVisitor)
}

protocol DeviceOperationStatus {}

struct SuccessNotification: DeviceOperationStatus, DeviceNotification {
    let deviceId: UUID
    
    func accept(_ visitor: any DeviceNotificationVisitor) {
        visitor.visit(self)
    }
}

struct FailedNotification: DeviceOperationStatus, DeviceNotification {
    let deviceId: UUID
    
    func accept(_ visitor: any DeviceNotificationVisitor) {
        visitor.visit(self)
    }
}

struct PairSuccessNotification: DeviceNotification {
    let deviceId: UUID
    let clientSlot: UInt8
    let name: String

    func accept(_ visitor: any DeviceNotificationVisitor) {
        visitor.visit(self)
    }
}

struct UnpairSuccessNotification: DeviceNotification {
    let deviceId: UUID
    let clientSlot: UInt8
    
    func accept(_ visitor: any DeviceNotificationVisitor) {
        visitor.visit(self)
    }
}


struct PresetSlotsNotification: DeviceNotification {
    let deviceId: UUID
    let presetSlots: [UInt8]
    
    func accept(_ visitor: any DeviceNotificationVisitor) {
        visitor.visit(self)
    }
}

struct DeviceInformationNotification: DeviceNotification {
    let deviceId: UUID
    let manufacturerName: String
    let modelNumber: String
    let hardwareRevision: String
    let firmwareRevision: String
    let serialNumber: String

    func accept(_ visitor: any DeviceNotificationVisitor) {
        visitor.visit(self)
    }
}

struct DeviceSettingsNotification: DeviceNotification {
    let deviceId: UUID
    let defaultPresetSlot: UInt8
    let standbyLightingEnabled: Bool
    let outletsSwitched: Bool
    let wirelessRemoteButtonOutletSlotsEnabled: [Int]
    
    func accept(_ visitor: any DeviceNotificationVisitor) {
        visitor.visit(self)
    }
}

struct DeviceStateNotification: DeviceNotification {
    let deviceId: UUID
    let targetTemperature: Double
    let actualTemperature: Double
    let outletSlot0IsRunning: Bool
    let outletSlot1IsRunning: Bool
    let secondsRemaining: Int
    let runningState: Device.RunningState

    func accept(_ visitor: any DeviceNotificationVisitor) {
        visitor.visit(self)
    }
}

struct ControlsOperatedNotification: DeviceNotification {
    let deviceId: UUID
    let selectedTemperature: Double?
    let targetTemperature: Double
    let actualTemperature: Double
    let outletSlot0IsRunning: Bool
    let outletSlot1IsRunning: Bool
    let secondsRemaining: Int
    let runningState: Device.RunningState
    
    func accept(_ visitor: any DeviceNotificationVisitor) {
        visitor.visit(self)
    }
}

struct OutletSettingsNotification: DeviceNotification, OutletNotification {
    let deviceId: UUID
    let outletSlot: Int
    let maximumDurationSeconds: Int
    let maximumTemperature: Double
    let minimumTemperature: Double
    let thresholdTemperature: Double

    func accept(_ visitor: any DeviceNotificationVisitor) {
        visitor.visit(self)
    }
    
    func accept(_ visitor: any OutletNotificationVisitor) {
        visitor.visit(self)
    }
}

struct DeviceNicknameNotification: DeviceNotification {
    let deviceId: UUID
    let nickname: String?

    func accept(_ visitor: any DeviceNotificationVisitor) {
        visitor.visit(self)
    }
    
}

struct PresetDetailsNotification: DeviceNotification, PresetNotification {
    let deviceId: UUID
    let presetSlot: UInt8
    let name: String
    let outletSlot: Int
    let targetTemperature: Double
    let durationSeconds: Int
    
    func accept(_ visitor: any DeviceNotificationVisitor) {
        visitor.visit(self)
    }
    
    func accept(_ visitor: any PresetNotificationVisitor) {
        visitor.visit(self)
    }
}

struct PairedClientSlotsNotification: DeviceNotification {
    let deviceId: UUID
    let pairedClientSlots: [UInt8]
    
    func accept(_ visitor: any DeviceNotificationVisitor) {
        visitor.visit(self)
    }
}

struct PairedClientDetailsNotification: DeviceNotification, ClientNotification {
    let deviceId: UUID
    let pairedClientSlot: UInt8
    let name: String?
    
    func accept(_ visitor: any DeviceNotificationVisitor) {
        visitor.visit(self)
    }
    
    func accept(_ visitor: any ClientNotificationVisitor) {
        visitor.visit(self)
    }
}

struct TechnicalInformationNotification: DeviceNotification {
    struct Valve {
        struct OutletSpec {
            let outletSlot: Int
            let type: Outlet.OutletType
        }
        
        let type: UInt16
        let softwareVersion: UInt16
        let outlets: [OutletSpec]
    }
    
    struct UI {
        struct ButtonSpec {
            let buttonSlot: Int
            let display: UserInterfaceButton.ButtonDisplayBehaviour
            let start: UserInterfaceButton.ButtonStartBehaviour
            let outletSlot: Int
        }
        
        let type: UInt16
        let softwareVersion: UInt16
        let buttons: [ButtonSpec]
    }

    struct Bluetooth {
        let type: UInt16
        let softwareVersion: UInt16
    }

    let deviceId: UUID
    let valve: Valve
    let ui: UI
    let bluetooth: Bluetooth

    func accept(_ visitor: any DeviceNotificationVisitor) {
        visitor.visit(self)
    }
}

struct UnknownNotification: DeviceNotification {
    let deviceId: UUID

    func accept(_ visitor: any DeviceNotificationVisitor) {
        visitor.visit(self)
    }
}

protocol DeviceNotificationVisitor: ClientNotificationVisitor, PresetNotificationVisitor, OutletNotificationVisitor {
    func visit(_ notification: DeviceInformationNotification)

    func visit(_ notification: SuccessNotification)
    func visit(_ notification: FailedNotification)

    func visit(_ notification: PairSuccessNotification)
    func visit(_ notification: UnpairSuccessNotification)
    func visit(_ notification: DeviceStateNotification)
    func visit(_ notification: ControlsOperatedNotification)
    func visit(_ notification: DeviceNicknameNotification)
    func visit(_ notification: PresetSlotsNotification)
    func visit(_ notification: PairedClientSlotsNotification)
    func visit(_ notification: DeviceSettingsNotification)
    func visit(_ notification: TechnicalInformationNotification)
    func visit(_ notification: UnknownNotification)
}

protocol ClientNotificationVisitor {
    func visit(_ notification: PairedClientDetailsNotification)
}

protocol PresetNotificationVisitor {
    func visit(_ notification: PresetDetailsNotification)
}

protocol OutletNotificationVisitor {
    func visit(_ notification: OutletSettingsNotification)
}

