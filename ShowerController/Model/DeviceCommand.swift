//
//  DeviceCommand.swift
//  ShowerController
//
//  Created by Nigel Hannam on 27/10/2024.
//

import Foundation

protocol DeviceCommand: Sendable {
    var deviceId: UUID { get }
    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response
}

protocol PairedDeviceCommand: DeviceCommand {
    var clientSlot: UInt8 { get }
    var clientSecret: Data { get }
}

protocol PresetCommand: PairedDeviceCommand {
    var presetSlot: UInt8 { get }
}

protocol PairedClientCommand: PairedDeviceCommand {
    var pairedClientSlot: UInt8 { get }
}

struct PairDevice: DeviceCommand {
    let deviceId: UUID
    var clientSecret: Data
    let clientName: String
    
    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct RequestDeviceInformation: PairedDeviceCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data

    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct RequestNickname: PairedDeviceCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data

    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct UpdateNickname: PairedDeviceCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data
    let nickname: String
    
    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct RequestState: PairedDeviceCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data

    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct RequestDeviceSettings: PairedDeviceCommand{
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data

    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct UpdateDefaultPresetSlot: PresetCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data
    let presetSlot: UInt8
    
    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct RequestPresetSlots: PairedDeviceCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data

    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct UpdateControllerSettings: PairedDeviceCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data
    let standbyLightingEnabled: Bool
    let outletsSwitched: Bool

    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct UpdateOutletSettings: PairedDeviceCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data
    let outletSlot: Int
    let maximumDurationSeconds: Int
    let maximumTemperature: Double
    let minimumTemperature: Double
    let thresholdTemperature: Double

    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct RequestOutletSettings: PairedDeviceCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data
    let outletSlot: Int

    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct UpdateWirelessRemoteButtonSettings: PairedDeviceCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data
    let outletSlotsEnabled: [Int]

    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct OperateOutletControls: PairedDeviceCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data
    let outletSlot0Running: Bool
    let outletSlot1Running: Bool
    let targetTemperature: Double
    let runningState: Device.RunningState
    
    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct RequestPresetDetails: PresetCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data
    let presetSlot: UInt8
    
    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct UpdatePresetDetails: PresetCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data
    let presetSlot: UInt8
    let name: String
    let outletSlot: Int
    let targetTemperature: Double
    let durationSeconds: Int
    
    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct DeletePresetDetails: PresetCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data
    let presetSlot: UInt8
    
    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct StartPreset: PresetCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data
    let presetSlot: UInt8
    
    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct UnpairDevice: PairedClientCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data
    let pairedClientSlot: UInt8
    
    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct RequestPairedClientSlots: PairedDeviceCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data

    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct RequestPairedClientDetails: PairedClientCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data
    let pairedClientSlot: UInt8
    
    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct RestartDevice: PairedDeviceCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data

    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct FactoryResetDevice: PairedDeviceCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data

    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct RequestTechnicalInformation: PairedDeviceCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data

    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct UnknownRequestTechnicalInformation: PairedDeviceCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data

    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}

struct UnknownCommand: PairedDeviceCommand {
    let deviceId: UUID
    var clientSlot: UInt8
    var clientSecret: Data

    func accept<V: DeviceCommandVisitor>(isolation: isolated (any Actor)?, _ visitor: V) async throws -> V.Response {
        return try await visitor.visit(isolation: isolation, self)
    }
}


protocol DeviceCommandVisitor {
    associatedtype Response: Sendable
    
    func visit(isolation: isolated (any Actor)?, _ command: PairDevice) async throws -> Response
    func visit(isolation: isolated (any Actor)?, _ command: UnpairDevice) async throws -> Response
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestPairedClientSlots) async throws -> Response
    func visit(isolation: isolated (any Actor)?, _ command: RequestPairedClientDetails) async throws -> Response

    func visit(isolation: isolated (any Actor)?, _ command: RequestDeviceInformation) async throws -> Response
    func visit(isolation: isolated (any Actor)?, _ command: RequestNickname) async throws -> Response
    func visit(isolation: isolated (any Actor)?, _ command: UpdateNickname) async throws -> Response
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestState) async throws -> Response
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestDeviceSettings) async throws -> Response
    func visit(isolation: isolated (any Actor)?, _ command: UpdateDefaultPresetSlot) async throws -> Response
    func visit(isolation: isolated (any Actor)?, _ command: UpdateControllerSettings) async throws -> Response

    func visit(isolation: isolated (any Actor)?, _ command: RequestPresetSlots) async throws -> Response
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestPresetDetails) async throws -> Response
    func visit(isolation: isolated (any Actor)?, _ command: UpdatePresetDetails) async throws -> Response
    func visit(isolation: isolated (any Actor)?, _ command: DeletePresetDetails) async throws -> Response

    func visit(isolation: isolated (any Actor)?, _ command: StartPreset) async throws -> Response
    func visit(isolation: isolated (any Actor)?, _ command: OperateOutletControls) async throws -> Response
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestOutletSettings) async throws -> Response
    func visit(isolation: isolated (any Actor)?, _ command: UpdateOutletSettings) async throws -> Response

    func visit(isolation: isolated (any Actor)?, _ command: UpdateWirelessRemoteButtonSettings) async throws -> Response
    

    func visit(isolation: isolated (any Actor)?, _ command: RestartDevice) async throws -> Response
    func visit(isolation: isolated (any Actor)?, _ command: FactoryResetDevice) async throws -> Response

    func visit(isolation: isolated (any Actor)?, _ command: RequestTechnicalInformation) async throws -> Response
    func visit(isolation: isolated (any Actor)?, _ command: UnknownRequestTechnicalInformation) async throws -> Response

    func visit(isolation: isolated (any Actor)?, _ command: UnknownCommand) async throws -> Response

}
