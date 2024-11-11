//
//  DeviceCommand.swift
//  ShowerController
//
//  Created by Nigel Hannam on 27/10/2024.
//

import Foundation

protocol DeviceCommand: Sendable {
    var deviceId: UUID { get }
    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response
}

protocol PairedDeviceCommand: DeviceCommand {}

protocol PresetCommand: PairedDeviceCommand {
    var presetSlot: UInt8 { get }
}

protocol ClientCommand: PairedDeviceCommand {
    var clientSlot: UInt8 { get }
}

struct PairDevice: DeviceCommand {
    let deviceId: UUID
    let clientName: String
    
    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct RequestNickname: PairedDeviceCommand {
    let deviceId: UUID
    
    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct UpdateNickname: PairedDeviceCommand {
    let deviceId: UUID
    let nickname: String
    
    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct RequestState: PairedDeviceCommand {
    let deviceId: UUID
    
    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct RequestDeviceSettings: PairedDeviceCommand{
    let deviceId: UUID
    
    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct UpdateDefaultPresetSlot: PresetCommand {
    let deviceId: UUID
    let presetSlot: UInt8
    
    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct RequestPresetSlots: PairedDeviceCommand {
    let deviceId: UUID
    
    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct UpdateControllerSettings: PairedDeviceCommand {
    let deviceId: UUID
    let standbyLightingEnabled: Bool
    let outletsSwitched: Bool

    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct UpdateOutletSettings: PairedDeviceCommand {
    let deviceId: UUID
    let outletSlot: Int
    let minimumTemperature: Double
    let maximumTemperature: Double
    let maximumDurationSeconds: Int

    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct RequestOutletSettings: PairedDeviceCommand {
    let deviceId: UUID
    let outletSlot: Int

    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct UpdateWirelessRemoteButtonSettings: PairedDeviceCommand {
    let deviceId: UUID
    let outletSlotsEnabled: [Int]

    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct OperateOutletControls: PairedDeviceCommand {
    let deviceId: UUID
    let outletSlot0Running: Bool
    let outletSlot1Running: Bool
    let targetTemperature: Double
    let timerState: TimerState
    
    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct RequestPresetDetails: PresetCommand {
    let deviceId: UUID
    let presetSlot: UInt8
    
    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct UpdatePresetDetails: PresetCommand {
    let deviceId: UUID
    let presetSlot: UInt8
    let name: String
    let outletSlot: Int
    let targetTemperature: Double
    let durationSeconds: Int
    
    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct DeletePresetDetails: PresetCommand {
    let deviceId: UUID
    let presetSlot: UInt8
    
    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct StartPreset: PresetCommand {
    let deviceId: UUID
    let presetSlot: UInt8
    
    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct UnpairDevice: ClientCommand {
    let deviceId: UUID
    let clientSlot: UInt8
    
    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct RequestPairedClientSlots: PairedDeviceCommand {
    let deviceId: UUID
    
    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct RequestPairedClientDetails: ClientCommand {
    let deviceId: UUID
    let clientSlot: UInt8
    
    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct RestartDevice: PairedDeviceCommand {
    let deviceId: UUID

    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct FactoryResetDevice: PairedDeviceCommand {
    let deviceId: UUID

    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct RequestTechnicalInformation: PairedDeviceCommand {
    let deviceId: UUID

    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct UnknownRequestTechnicalInformation: PairedDeviceCommand {
    let deviceId: UUID

    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}

struct UnknownCommand: PairedDeviceCommand {
    let deviceId: UUID

    func accept<V: DeviceCommandVisitor>(_ visitor: V) async throws -> V.Response {
        return try await visitor.visit(self)
    }
}


protocol DeviceCommandVisitor {
    associatedtype Response: Sendable
    
    func visit(_ command: PairDevice) async throws -> Response
    func visit(_ command: UnpairDevice) async throws -> Response
    
    func visit(_ command: RequestPairedClientSlots) async throws -> Response
    func visit(_ command: RequestPairedClientDetails) async throws -> Response

    func visit(_ command: RequestNickname) async throws -> Response
    func visit(_ command: UpdateNickname) async throws -> Response
    
    func visit(_ command: RequestState) async throws -> Response
    
    func visit(_ command: RequestDeviceSettings) async throws -> Response
    func visit(_ command: UpdateDefaultPresetSlot) async throws -> Response
    func visit(_ command: UpdateControllerSettings) async throws -> Response

    func visit(_ command: RequestPresetSlots) async throws -> Response
    
    func visit(_ command: RequestPresetDetails) async throws -> Response
    func visit(_ command: UpdatePresetDetails) async throws -> Response
    func visit(_ command: DeletePresetDetails) async throws -> Response

    func visit(_ command: StartPreset) async throws -> Response
    func visit(_ command: OperateOutletControls) async throws -> Response
    
    func visit(_ command: RequestOutletSettings) async throws -> Response
    func visit(_ command: UpdateOutletSettings) async throws -> Response

    func visit(_ command: UpdateWirelessRemoteButtonSettings) async throws -> Response
    

    func visit(_ command: RestartDevice) async throws -> Response
    func visit(_ command: FactoryResetDevice) async throws -> Response

    func visit(_ command: RequestTechnicalInformation) async throws -> Response
    func visit(_ command: UnknownRequestTechnicalInformation) async throws -> Response

    func visit(_ command: UnknownCommand) async throws -> Response

}
