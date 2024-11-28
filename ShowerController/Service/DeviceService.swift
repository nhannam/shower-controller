//
//  DeviceService.swift
//  ShowerController
//
//  Created by Nigel Hannam on 04/11/2024.
//

import Foundation
import SwiftData
import AsyncAlgorithms
import AsyncBluetooth

enum DeviceServiceError: Error {
    case deviceNotFound
    case clientNotFound
    case deviceNotPaired
    case commandFailed
    case internalError
}

// @ModelActor creates a single arg init, which prevents us passing the BluetoothService in
actor DeviceService: ModelActor {
    private static let logger = LoggerFactory.logger(DeviceService.self)
    private static let author = "DeviceService"
    
    private let bluetoothService: BluetoothService
    nonisolated let modelExecutor: any ModelExecutor
    nonisolated let modelContainer: ModelContainer

    init(modelContainer: ModelContainer, bluetoothService: BluetoothService) {
        let modelContext = ModelContext(modelContainer)
        modelContext.author = Self.author
        
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
        self.modelContainer = modelContainer
        self.bluetoothService = bluetoothService
    }
    
    private func errorBoundary(_ block: () async throws -> Void) async throws -> Void {
        do {
            try await block()
        } catch let error as DeviceServiceError {
            throw error
        } catch BluetoothServiceError.cancelled {
            Self.logger.info("Bluetooth Operation was cancelled")
        } catch let error as BluetoothServiceError {
            throw error
        } catch {
            Self.logger.debug("Unexpected error: \(error)")
            throw DeviceServiceError.internalError
        }
    }
    
    private func getClient() throws -> Client {
        do {
            let findAll = FetchDescriptor<Client>()
            if let client = try modelContext.fetch(findAll).first {
                return client
            } else {
                throw DeviceServiceError.clientNotFound
            }
        }
    }

    private func findDeviceById(_ id: UUID) throws -> Device? {
        let findById = FetchDescriptor<Device>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(findById).first
    }

    private func getDeviceById(_ id: UUID) throws -> Device {
        do {
            if let device = try findDeviceById(id) {
                return device
            } else {
                throw DeviceServiceError.deviceNotFound
            }
        }
    }
    
    private func getPairedDevice(_ id: UUID) async throws -> (Device, Client) {
        let device = try getDeviceById(id)
        let client = try getClient()
        return (device, client)
    }
    
    private func executeCommand(_ command: DeviceCommand) async throws {
        let notification = try await bluetoothService.executeCommand(command)

        switch notification {
        case is FailedNotification:
            throw DeviceServiceError.commandFailed
            
        case let pairSuccess as PairSuccessNotification:
            try modelContext.transaction {
                modelContext.insert(
                    Device(
                        id: pairSuccess.deviceId,
                        name: pairSuccess.name,
                        clientSlot: pairSuccess.clientSlot,
                        outlets: [
                            Outlet(outletSlot: Outlet.outletSlot0, type: .overhead),
                            Outlet(outletSlot: Outlet.outletSlot1, type: .bath)
                        ]
                    )
                )
            }
            
        default:
            try modelContext.transaction {
                let device = try getDeviceById(notification.deviceId)
                notification.accept(DeviceNotificatonApplier(device: device, modelContext: modelContext))
            }
        }
    }

    private func executeCommands(_ commands: [DeviceCommand]) async throws {
        for command in commands {
            try await executeCommand(command)
        }
    }

    func requestDeviceDetails(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)
            
            try await executeCommands([
                RequestState(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret
                ),
                RequestNickname(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret
                ),
            ])
        }
    }
    
    func updateNickname(_ deviceId: UUID, nickname: String) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)

            try await stopOutletsAndWaitForLockoutToExipire(device: device, client: client)
            
            try await executeCommands([
                UpdateNickname(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret,
                    nickname: nickname
                ),
                RequestNickname(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret
                )
            ])
        }
    }
    
    func requestState(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)

            try await executeCommand(
                RequestState(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret
                )
            )
        }
    }
    
    func startOutlet(_ deviceId: UUID, outletSlot: Int) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)

            let temperature = device.selectedTemperature
            let newRunningState = device.getRunningStateForTemperature(temperature: temperature, outletSlot: outletSlot)
            
            try await executeCommand(
                OperateOutletControls(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret,
                    outletSlot0Running: outletSlot == Outlet.outletSlot0,
                    outletSlot1Running: outletSlot == Outlet.outletSlot1,
                    targetTemperature: temperature,
                    runningState: newRunningState
                )
            )
        }
    }
    
    func updateSelectedTemperature(_ deviceId: UUID, targetTemperature: Double) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)

            try await executeCommand(
                OperateOutletControls(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret,
                    outletSlot0Running: device.isOutletRunning(outletSlot: Outlet.outletSlot0),
                    outletSlot1Running: device.isOutletRunning(outletSlot: Outlet.outletSlot1),
                    targetTemperature: targetTemperature,
                    runningState: device.getRunningStateForTemperature(temperature: targetTemperature)
                )
            )
        }
    }
    
    func startPreset(_ deviceId: UUID, presetSlot: UInt8) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)

            try await executeCommand(
                StartPreset(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret,
                    presetSlot: presetSlot
                )
            )
        }
    }
    
    func pauseOutlets(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)

            try await executeCommand(
                OperateOutletControls(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret,
                    outletSlot0Running: false,
                    outletSlot1Running: false,
                    targetTemperature: device.selectedTemperature,
                    runningState: .paused
                )
            )
        }
    }
    
    func requestOutletSettings(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)
            try await executeCommands(
                device.outlets.map({ outlet in
                    RequestOutletSettings(
                        deviceId: device.id,
                        clientSlot: device.clientSlot,
                        clientSecret: client.secret,
                        outletSlot: outlet.outletSlot
                    )
                })
            )
        }
    }

    func requestPresets(_ deviceId: UUID) async throws {
        try await errorBoundary {
            do {
                let (device, client) = try await getPairedDevice(deviceId)
                try await executeCommands([
                    // Device settings include the default preset slot
                    RequestDeviceSettings(
                        deviceId: device.id,
                        clientSlot: device.clientSlot,
                        clientSecret: client.secret
                    ),
                    RequestPresetSlots(
                        deviceId: device.id,
                        clientSlot: device.clientSlot,
                        clientSecret: client.secret
                    ),
                ])
            }
            
            // TBC: I've split these into separate blocks with their own
            // device lookup because this block needs to see the changes
            // triggered in response to the first block, and it seems unlikely
            // that swift data will share the info between different modelContexts
            do {
                let (device, client) = try await getPairedDevice(deviceId)
                try await executeCommands(
                    device.presets.map({ preset in
                        RequestPresetDetails(
                            deviceId: device.id,
                            clientSlot: device.clientSlot,
                            clientSecret: client.secret,
                            presetSlot: preset.presetSlot
                        )
                    })
                )
            }
        }
    }
    
    private func stopOutletsAndWaitForLockoutToExipire(device: Device, client: Client) async throws {
        // Most update operations require the device to be stopped before they're permitted.
        if (!device.isStopped) {
            try await executeCommand(
                OperateOutletControls(
                   deviceId: device.id,
                   clientSlot: device.clientSlot,
                   clientSecret: client.secret,
                   outletSlot0Running: false,
                   outletSlot1Running: false,
                   targetTemperature: device.selectedTemperature,
                   // Move to off state
                   runningState: .off
               )
            )
        }
        
        // They also require a delay of 5 seconds after stopping the outlets.
        // Re-fetch the device as the stop command may have updated the lockout time
        let updatedDevice = try getDeviceById(device.id)
        if updatedDevice.isLockedOut {
            let lockoutTimeRemaining = updatedDevice.updatesLockedOutUntil.timeIntervalSinceNow
            Self.logger.debug("Lock seconds remaining: \(String(describing: lockoutTimeRemaining))")
            try await Task.sleep(for: .milliseconds(lockoutTimeRemaining * 1000))
        }
    }
    
    private func doUpdatePreset(
        device: Device,
        client: Client,
        presetSlot: UInt8,
        name: String,
        outletSlot: Int,
        targetTemperature: Double,
        durationSeconds: Int,
        makeDefault: Bool
    ) async throws {
        try await stopOutletsAndWaitForLockoutToExipire(device: device, client: client)

        var commands: [DeviceCommand] = [
            UpdatePresetDetails(
                deviceId: device.id,
                clientSlot: device.clientSlot,
                clientSecret: client.secret,
                presetSlot: presetSlot,
                name: name,
                outletSlot: outletSlot,
                targetTemperature: targetTemperature,
                durationSeconds: durationSeconds),
            RequestPresetDetails(
                deviceId: device.id,
                clientSlot: device.clientSlot,
                clientSecret: client.secret,
                presetSlot: presetSlot
            )
        ]
        if (makeDefault) {
            commands += [
                UpdateDefaultPresetSlot(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret,
                    presetSlot: presetSlot
                ),
                RequestDeviceSettings(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret
                )
            ]
        }

        try await executeCommands(commands)
    }
    
    func createPresetDetails(
        _ deviceId: UUID,
        name: String,
        outletSlot: Int,
        targetTemperature: Double,
        durationSeconds: Int,
        makeDefault: Bool
    ) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)

            // choose a slot
            if let availableSlot = device.nextAvailablePresetSlot {
                try await doUpdatePreset(
                    device: device,
                    client: client,
                    presetSlot: availableSlot,
                    name: name,
                    outletSlot: outletSlot,
                    targetTemperature: targetTemperature,
                    durationSeconds: durationSeconds,
                    makeDefault: makeDefault
                )
            }
        }
    }
    
    
    func updatePresetDetails(
        _ deviceId: UUID,
        presetSlot: UInt8,
        name: String,
        outletSlot: Int,
        targetTemperature: Double,
        durationSeconds: Int,
        makeDefault: Bool
    ) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)

            if device.getPresetBySlot(presetSlot) != nil {
                try await doUpdatePreset(
                    device: device,
                    client: client,
                    presetSlot: presetSlot,
                    name: name,
                    outletSlot: outletSlot,
                    targetTemperature: targetTemperature,
                    durationSeconds: durationSeconds,
                    makeDefault: makeDefault
                )
            }
        }
    }
    
    func deletePresetDetails(_ deviceId: UUID, presetSlot: UInt8) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)

            if device.getPresetBySlot(presetSlot) != nil {
                try await stopOutletsAndWaitForLockoutToExipire(device: device, client: client)

                try await executeCommands([
                    DeletePresetDetails(
                        deviceId: device.id,
                        clientSlot: device.clientSlot,
                        clientSecret: client.secret,
                        presetSlot: presetSlot
                    ),
                    RequestPresetSlots(
                        deviceId: device.id,
                        clientSlot: device.clientSlot,
                        clientSecret: client.secret
                    )
                ])
            }
        }
    }
    
    func pair(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let client = try getClient()
            try await executeCommand(
                PairDevice(
                    deviceId: deviceId,
                    clientSecret: client.secret,
                    clientName: client.name
                )
            )
        }
        try await bluetoothService.disconnect(deviceId)
    }
    
    func unpair(_ deviceId: UUID, clientSlot: UInt8) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)

            try await stopOutletsAndWaitForLockoutToExipire(device: device, client: client)

            let isCurrentClient = device.clientSlot == clientSlot
            
            var thrown: Error? = nil
            do {
                try await executeCommands([
                    UnpairDevice(
                        deviceId: device.id,
                        clientSlot: device.clientSlot,
                        clientSecret: client.secret,
                        pairedClientSlot: clientSlot
                    ),
                    RequestPairedClientSlots(
                        deviceId: device.id,
                        clientSlot: device.clientSlot,
                        clientSecret: client.secret
                    )
                ])
            } catch {
                thrown = error
            }

            
            if isCurrentClient {
                // If we are already unpaired, the bluetooth unpair might fail
                // So get rid of the paired device anyway
                try modelContext.transaction {
                    modelContext.delete(device)
                }
                try await bluetoothService.disconnect(deviceId)
            }
            
            if let thrown {
                throw thrown
            }
        }
    }
    
    func requestPairedClients(_ deviceId: UUID) async throws {
        try await errorBoundary {
            do {
                let (device, client) = try await getPairedDevice(deviceId)
                try await executeCommand(
                    RequestPairedClientSlots(
                        deviceId: device.id,
                        clientSlot: device.clientSlot,
                        clientSecret: client.secret
                    )
                )
            }
            
            do {
                let (device, client) = try await getPairedDevice(deviceId)
                try await executeCommands(
                    device.pairedClients.map({ pairedClient in
                        RequestPairedClientDetails(
                            deviceId: device.id,
                            clientSlot: device.clientSlot,
                            clientSecret: client.secret,
                            pairedClientSlot: pairedClient.clientSlot
                        )
                    })
                )
            }
        }
    }
    
    func requestSettings(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)
            try await executeCommand(
                RequestDeviceSettings(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret
                )
            )
        }
    }
    
    func updateOutletSettings(_ deviceId: UUID, outletSlot: Int, temperatureRange: ClosedRange<Double>, maximumDurationSeconds: Int) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)
            
            try await stopOutletsAndWaitForLockoutToExipire(device: device, client: client)

            let presetClamping: [DeviceCommand] = device.presets
                .filter({ $0.outlet.outletSlot == outletSlot })
                .filter({ preset in
                    preset.targetTemperature.clampToRange(range: temperatureRange) != preset.targetTemperature ||
                    preset.durationSeconds > maximumDurationSeconds
                })
                .flatMap({ preset in
                    let arr: [DeviceCommand] = [
                        UpdatePresetDetails(
                            deviceId: deviceId,
                            clientSlot: device.clientSlot,
                            clientSecret: client.secret,
                            presetSlot: preset.presetSlot,
                            name: preset.name,
                            outletSlot: outletSlot,
                            targetTemperature: preset.targetTemperature.clampToRange(range: temperatureRange),
                            durationSeconds: min(preset.durationSeconds, maximumDurationSeconds)
                        ),
                        RequestPresetDetails(
                            deviceId: deviceId,
                            clientSlot: device.clientSlot,
                            clientSecret: client.secret,
                            presetSlot: preset.presetSlot
                        )
                    ]
                    return arr
                })
            
            try await executeCommands(presetClamping + [
                UpdateOutletSettings(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret,
                    outletSlot: outletSlot,
                    maximumDurationSeconds: maximumDurationSeconds,
                    maximumTemperature: temperatureRange.upperBound,
                    minimumTemperature: temperatureRange.lowerBound,
                    thresholdTemperature: temperatureRange.lowerBound
                ),
                RequestOutletSettings(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret,
                    outletSlot: outletSlot
                )
            ])
        }
    }
    
    func updateControllerSettings(_ deviceId: UUID, standbyLightingEnabled: Bool, outletsSwitched: Bool) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)

            try await stopOutletsAndWaitForLockoutToExipire(device: device, client: client)

            try await executeCommands([
                UpdateControllerSettings(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret,
                    standbyLightingEnabled: standbyLightingEnabled,
                    outletsSwitched: outletsSwitched
                ),
                RequestDeviceSettings(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret
                )
            ])
        }
    }
    
    func updateWirelessRemoteButtonSettings(_ deviceId: UUID, wirelessRemoteButtonOutletsEnabled: [Int]) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)

            try await stopOutletsAndWaitForLockoutToExipire(device: device, client: client)

            try await executeCommands([
                UpdateWirelessRemoteButtonSettings(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret,
                    outletSlotsEnabled: wirelessRemoteButtonOutletsEnabled
                ),
                RequestDeviceSettings(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret
                )
            ])
        }
    }
    
    func restartDevice(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)

            try await stopOutletsAndWaitForLockoutToExipire(device: device, client: client)

            try await executeCommand(
                RestartDevice(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret
                )
            )
        }
    }

    func factoryReset(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)

            try await stopOutletsAndWaitForLockoutToExipire(device: device, client: client)
            
            try await executeCommand(
                FactoryResetDevice(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret
                )
            )
        }
    }


    func requestTechnicalInformation(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)

            try await executeCommands([
                RequestDeviceInformation(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret
                ),
                RequestTechnicalInformation(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret
                )
            ])
        }
    }
    
    
    func unknownCommand(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let (device, client) = try await getPairedDevice(deviceId)

            try await stopOutletsAndWaitForLockoutToExipire(device: device, client: client)

            try await executeCommand(
                UnknownCommand(
                    deviceId: device.id,
                    clientSlot: device.clientSlot,
                    clientSecret: client.secret
                )
            )
        }
    }
}
