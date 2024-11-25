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
    case internalError
}

// @ModelActor creates a single arg init, which prevents us passing the BluetoothService in
actor DeviceService: ModelActor {
    private static let logger = LoggerFactory.logger(DeviceService.self)
    private static let author = "DeviceService"
    
    static let UNPAIRED_PREDICATE = #Predicate<Device> { $0.clientSlot == nil }
    static let PAIRED_PREDICATE = #Predicate<Device> { $0.clientSlot != nil }

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

    func suspendProcessing() async throws {
        try await errorBoundary {
            try await bluetoothService.stopScan()
            try await bluetoothService.disconnectAll()
        }
    }

    func startScan() async throws {
        try await errorBoundary {
            try modelContext.transaction {
                try modelContext.delete(
                    model: Device.self,
                    where: Self.UNPAIRED_PREDICATE
                )
            }
            try await bluetoothService.startScan()
        }
    }
    
    func stopScan() async throws {
        try await bluetoothService.stopScan()
    }
    
    func requestDeviceDetails(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let device = try getDeviceById(deviceId)
            
            try await bluetoothService.dispatchCommands([
                RequestState(deviceId: device.id),
                RequestNickname(deviceId: device.id),
            ])
        }
    }
    
    func updateNickname(_ deviceId: UUID, nickname: String) async throws {
        try await errorBoundary {
            let device = try getDeviceById(deviceId)
            
            try await stopOutletsAndWaitForLockoutToExipire(device)
            
            try await bluetoothService.dispatchCommands([
                UpdateNickname(deviceId: device.id, nickname: nickname),
                RequestNickname(deviceId: device.id)
            ])
        }
    }
    
    func requestState(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let device = try getDeviceById(deviceId)
            try await bluetoothService.dispatchCommand(RequestState(deviceId: device.id))
        }
    }
    
    func startOutlet(_ deviceId: UUID, outletSlot: Int) async throws {
        try await errorBoundary {
            let device = try getDeviceById(deviceId)
            try await bluetoothService.dispatchCommand(
                OperateOutletControls(
                    deviceId: device.id,
                    outletSlot0Running: outletSlot == Outlet.outletSlot0,
                    outletSlot1Running: outletSlot == Outlet.outletSlot1,
                    targetTemperature: device.selectedTemperature,
                    runningState: .running
                )
            )
        }
    }
    
    func updateSelectedTemperature(_ deviceId: UUID, targetTemperature: Double) async throws {
        try await errorBoundary {
            let device = try getDeviceById(deviceId)
            try await bluetoothService.dispatchCommand(
                OperateOutletControls(
                    deviceId: device.id,
                    outletSlot0Running: device.getOutletBySlot(outletSlot: Outlet.outletSlot0)?.isRunning ?? false,
                    outletSlot1Running: device.getOutletBySlot(outletSlot: Outlet.outletSlot1)?.isRunning ?? false,
                    targetTemperature: targetTemperature,
                    runningState: device.runningState
                )
            )
        }
    }
    
    func startPreset(_ deviceId: UUID, presetSlot: UInt8) async throws {
        try await errorBoundary {
            let device = try getDeviceById(deviceId)
            try await bluetoothService.dispatchCommand(StartPreset(deviceId: device.id, presetSlot: presetSlot))
        }
    }
    
    func stopOutlets(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let device = try getDeviceById(deviceId)
            try await bluetoothService.dispatchCommand(
                OperateOutletControls(
                   deviceId: device.id,
                   outletSlot0Running: false,
                   outletSlot1Running: false,
                   targetTemperature: device.selectedTemperature,
                   // Follow controller behaviour by settin to paused rather than stopped
                   runningState: .paused
               )
            )
        }
    }
    
    func requestOutletSettings(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let device = try getDeviceById(deviceId)
            try await bluetoothService.dispatchCommands(
                device.outlets.map({ outlet in
                    RequestOutletSettings(deviceId: device.id, outletSlot: outlet.outletSlot)
                })
            )
        }
    }

    func requestPresets(_ deviceId: UUID) async throws {
        try await errorBoundary {
            do {
                let device = try getDeviceById(deviceId)
                try await bluetoothService.dispatchCommands([
                    // Device settings include the default preset slot
                    RequestDeviceSettings(deviceId: device.id),
                    RequestPresetSlots(deviceId: device.id),
                ])
            }
            
            // TBC: I've split these into separate blocks with their own
            // device lookup because this block needs to see the changes
            // triggered in response to the first block, and it seems unlikely
            // that swift data will share the info between different modelContexts
            do {
                let device = try getDeviceById(deviceId)
                try await bluetoothService.dispatchCommands(
                    device.presets.map({ preset in
                        RequestPresetDetails(deviceId: device.id, presetSlot: preset.presetSlot)
                    })
                )
            }
        }
    }
    
    private func stopOutletsAndWaitForLockoutToExipire(_ device: Device) async throws {
        // Most update operations require the device to be stopped before they're permitted.
        if (device.isTimerRunning) {
            try await bluetoothService.dispatchCommand(
                OperateOutletControls(
                   deviceId: device.id,
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
        let lockoutTime = try getDeviceById(device.id).updatesLockedOutUntil
        let lockoutTimeRemaining = lockoutTime.timeIntervalSinceNow
        if (lockoutTimeRemaining > 0) {
            Self.logger.debug("Lock seconds remaining: \(String(describing: lockoutTimeRemaining))")
            try await Task.sleep(for: .milliseconds(lockoutTimeRemaining * 1000))
        }
    }
    
    private func doUpdatePreset(
        _ device: Device,
        presetSlot: UInt8,
        name: String,
        outletSlot: Int,
        targetTemperature: Double,
        durationSeconds: Int,
        makeDefault: Bool
    ) async throws {
        try await stopOutletsAndWaitForLockoutToExipire(device)
        
        var commands: [DeviceCommand] = [
            UpdatePresetDetails(
                deviceId: device.id,
                presetSlot: presetSlot,
                name: name,
                outletSlot: outletSlot,
                targetTemperature: targetTemperature,
                durationSeconds: durationSeconds),
            RequestPresetDetails(deviceId: device.id, presetSlot: presetSlot)
        ]
        if (makeDefault) {
            commands.append(UpdateDefaultPresetSlot(deviceId: device.id, presetSlot: presetSlot))
            commands.append(RequestDeviceSettings(deviceId: device.id))
        }

        try await bluetoothService.dispatchCommands(commands)
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
            let device = try getDeviceById(deviceId)
            // choose a slot
            if let availableSlot = device.getNextAvailablePresetSlot() {
                try await doUpdatePreset(
                    device,
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
            let device = try getDeviceById(deviceId)
            
            if device.getPresetBySlot(presetSlot) != nil {
                try await doUpdatePreset(
                    device,
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
            let device = try getDeviceById(deviceId)
            if device.getPresetBySlot(presetSlot) != nil {
                try await stopOutletsAndWaitForLockoutToExipire(device)
                
                try await bluetoothService.dispatchCommands([
                    DeletePresetDetails(deviceId: device.id, presetSlot: presetSlot),
                    RequestPresetSlots(deviceId: device.id)
                ])
            }
        }
    }
    
    func pair(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let device = try getDeviceById(deviceId)
            let client = try getClient()
            try await bluetoothService.dispatchCommand(
                PairDevice(deviceId: device.id, clientName: client.name)
            )
        }
        try await bluetoothService.disconnect(deviceId)
    }
    
    func unpair(_ deviceId: UUID, clientSlot: UInt8) async throws {
        try await errorBoundary {
            let device = try getDeviceById(deviceId)
            
            let isCurrentClient = device.clientSlot == clientSlot
            
            try await stopOutletsAndWaitForLockoutToExipire(device)
            
            do {
                try await bluetoothService.dispatchCommands([
                    UnpairDevice(deviceId: device.id, clientSlot: clientSlot),
                    RequestPairedClientSlots(deviceId: device.id)
                ])
            } catch {
                if isCurrentClient {
                    // If we are already unpaired, the bluetooth unpair might fail
                    // So reload the device and ensure we mark it as unpaired anyway
                    try modelContext.transaction {
                        let device = try getDeviceById(deviceId)
                        UnpairSuccessNotification(deviceId: deviceId, clientSlot: clientSlot)
                            .accept(DeviceNotificatonApplier(device: device, modelContext: modelContext))
                    }
                }
            }
        }
    }
    
    func requestPairedClients(_ deviceId: UUID) async throws {
        try await errorBoundary {
            do {
                let device = try getDeviceById(deviceId)
                try await bluetoothService.dispatchCommand(
                    RequestPairedClientSlots(deviceId: device.id)
                )
            }
            
            do {
                let device = try getDeviceById(deviceId)
                try await bluetoothService.dispatchCommands(
                    device.pairedClients.map({ client in
                        RequestPairedClientDetails(deviceId: device.id, clientSlot: client.clientSlot)
                    })
                )
            }
        }
    }
    
    func requestSettings(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let device = try getDeviceById(deviceId)
            try await bluetoothService.dispatchCommand(RequestDeviceSettings(deviceId: device.id))
        }
    }
    
    func updateOutletSettings(_ deviceId: UUID, outletSlot: Int, temperatureRange: ClosedRange<Double>, maximumDurationSeconds: Int) async throws {
        try await errorBoundary {
            let device = try getDeviceById(deviceId)
            
            try await stopOutletsAndWaitForLockoutToExipire(device)
            
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
                            presetSlot: preset.presetSlot,
                            name: preset.name,
                            outletSlot: outletSlot,
                            targetTemperature: preset.targetTemperature.clampToRange(range: temperatureRange),
                            durationSeconds: min(preset.durationSeconds, maximumDurationSeconds)
                        ),
                        RequestPresetDetails(deviceId: deviceId, presetSlot: preset.presetSlot)
                    ]
                    return arr
                })
            
            try await bluetoothService.dispatchCommands(presetClamping + [
                UpdateOutletSettings(
                    deviceId: device.id,
                    outletSlot: outletSlot,
                    minimumTemperature: temperatureRange.lowerBound,
                    maximumTemperature: temperatureRange.upperBound,
                    maximumDurationSeconds: maximumDurationSeconds
                ),
                RequestOutletSettings(deviceId: device.id, outletSlot: outletSlot)
            ])
        }
    }
    
    func updateControllerSettings(_ deviceId: UUID, standbyLightingEnabled: Bool, outletsSwitched: Bool) async throws {
        try await errorBoundary {
            let device = try getDeviceById(deviceId)
            
            try await stopOutletsAndWaitForLockoutToExipire(device)
            
            try await bluetoothService.dispatchCommands([
                UpdateControllerSettings(deviceId: device.id, standbyLightingEnabled: standbyLightingEnabled, outletsSwitched: outletsSwitched),
                RequestDeviceSettings(deviceId: device.id)
            ])
        }
    }
    
    func updateWirelessRemoteButtonSettings(_ deviceId: UUID, wirelessRemoteButtonOutletsEnabled: [Int]) async throws {
        try await errorBoundary {
            let device = try getDeviceById(deviceId)
            
            try await stopOutletsAndWaitForLockoutToExipire(device)
            
            try await bluetoothService.dispatchCommands([
                UpdateWirelessRemoteButtonSettings(
                    deviceId: device.id,
                    outletSlotsEnabled: wirelessRemoteButtonOutletsEnabled
                ),
                RequestDeviceSettings(deviceId: device.id)
            ])
        }
    }
    
    func restartDevice(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let device = try getDeviceById(deviceId)

            try await stopOutletsAndWaitForLockoutToExipire(device)

            try await bluetoothService.dispatchCommand(RestartDevice(deviceId: device.id))
        }
    }

    func factoryReset(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let device = try getDeviceById(deviceId)

            try await stopOutletsAndWaitForLockoutToExipire(device)

            try await bluetoothService.dispatchCommand(FactoryResetDevice(deviceId: device.id))
        }
    }


    func requestTechnicalInformation(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let device = try getDeviceById(deviceId)
            try await bluetoothService.requestDeviceInformation(deviceId)
            try await bluetoothService.dispatchCommand(RequestTechnicalInformation(deviceId: device.id))
        }
    }
    
    
    func unknownCommand(_ deviceId: UUID) async throws {
        try await errorBoundary {
            let device = try getDeviceById(deviceId)

            try await stopOutletsAndWaitForLockoutToExipire(device)

            try await bluetoothService.dispatchCommand(UnknownCommand(deviceId: device.id))
        }
    }
}
