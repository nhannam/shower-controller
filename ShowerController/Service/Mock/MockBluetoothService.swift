//
//  MockBluetoothService.swift
//  ShowerController
//
//  Created by Nigel Hannam on 19/11/2024.
//

import Foundation
import SwiftData

// @ModelActor creates a single arg init, which prevents us passing the BluetoothService in
actor MockBluetoothService: ModelActor, BluetoothService {
    static let device1Id = UUID()
    static let device2Id = UUID()
    private static let author = "MockBluetoothService"

    nonisolated let modelExecutor: any ModelExecutor
    nonisolated let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        let modelContext = ModelContext(modelContainer)
        modelContext.author = Self.author
        
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
        self.modelContainer = modelContainer
    }

    func dispatchCommand(_ command: any DeviceCommand) async throws {
        let deviceActor = try MockDeviceActor(modelContainer: modelContainer, deviceId: command.deviceId)
        try await deviceActor.executeCommand(command)
    }
    
    func disconnectAll() async throws {
        // Nothing to do
    }
    
    func disconnect(_ deviceId: UUID) async throws {
        // Nothing to do
    }
    
    func startScan() async throws {
        try await Task.sleep(for: .milliseconds(500))
        try self.modelContext.transaction {
            let outlet0 = Outlet(outletSlot: Outlet.outletSlot0, type: .overhead, isRunning: false, minimumTemperature: Outlet.minimumPermittedTemperature, maximumTemperature: Outlet.maximumPermittedTemperature, maximumDurationSeconds: Outlet.maximumPermittedDurationSeconds)
            let outlet1 = Outlet(outletSlot: Outlet.outletSlot1, type: .bath, isRunning: false, minimumTemperature: Outlet.minimumPermittedTemperature, maximumTemperature: Outlet.maximumPermittedTemperature, maximumDurationSeconds: Outlet.maximumPermittedDurationSeconds)
            self.modelContext.insert(
                Device(
                    id: Self.device1Id,
                    name: "Mock Device",
                    nickname: "Mock Bathroom",
                    manufacturerName: "Moira",
                    modelNumber: "1001",
                    hardwareRevision: "2001",
                    firmwareRevision: "3001",
                    serialNumber: "4001",
                    outlets: [ outlet0, outlet1 ],
                    outletsSwitched: false,
                    presets: [
                        Preset(presetSlot: 0, name: "Warm Bath", outlet: outlet1, targetTemperature: 45, durationSeconds: 1220),
                        Preset(presetSlot: 1, name: "Short Run", outlet: outlet1, targetTemperature: 42, durationSeconds: 10)
                    ],
                    defaultPresetSlot: 0,
                    pairedClients: [
                        PairedClient(clientSlot: 0, name: "Paired Client 0"),
                        PairedClient(clientSlot: 1, name: "Paired Client 1")
                    ],
                    technicalInformation: TechnicalInformation(
                        valveType: 44,
                        valveSoftwareVersion: 8,
                        uiType: 33,
                        uiSoftwareVersion: 6,
                        bluetoothSoftwareVersion: 4
                    ),
                    standbyLightingEnabled: true,
                    runningState: .off,
                    lastRunningStateReceived: Date.distantPast,
                    updatesLockedOutUntil: Date.distantPast,
                    selectedTemperature: 42,
                    targetTemperature: 42,
                    actualTemperature: 30,
                    secondsRemaining: 1800
                )
            )
        }
    }
    
    func stopScan() async throws {
        // nothing to do
    }
    
    func requestDeviceInformation(_ deviceId: UUID) async throws {
        // nothing to do
    }
}

actor MockDeviceActor: SwiftData.ModelActor, DeviceCommandVisitor {
    typealias Response = DeviceNotification?

    private static let author = "MockDeviceActor"

    nonisolated let modelExecutor: any SwiftData.ModelExecutor
    nonisolated let modelContainer: SwiftData.ModelContainer
    private let pauseTimerDurationSeconds = 300

    let mockDevice: Device
    
    var clientSlot: UInt8 {
        return mockDevice.clientSlot ?? 0
    }
    
    var outlet0MaxDuration: Int {
        mockDevice.getOutletBySlot(outletSlot: Outlet.outletSlot0)?.maximumDurationSeconds ?? 1800
    }

    init(modelContainer: SwiftData.ModelContainer, deviceId: UUID) throws {
        let modelContext = ModelContext(modelContainer)
        modelContext.author = Self.author
        
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
        self.modelContainer = modelContainer
        
        let findById = FetchDescriptor<Device>(
            predicate: #Predicate { $0.id == deviceId }
        )
        if let device = try modelContext.fetch(findById).first {
            self.mockDevice = device
        } else {
            throw BluetoothServiceError.deviceNotFound
        }
    }
    
    func executeCommand(_ command: DeviceCommand) async throws {
        guard (command.deviceId == mockDevice.id) else {
            throw BluetoothServiceError.internalError
        }
        
        if let notification = try await command.accept(self) {
            try modelContext.transaction {
                notification.accept(DeviceNotificatonApplier(device: mockDevice, modelContext: modelContext))
            }
        }
    }
    
    func visit(_ command: PairDevice) async throws -> Response {
        return PairSuccessNotification(
            deviceId: command.deviceId,
            clientSlot: clientSlot
        )
    }
    
    func visit(_ command: UnpairDevice) async throws -> Response {
        return UnpairSuccessNotification(
            deviceId: command.deviceId,
            clientSlot: command.clientSlot
        )
    }
    
    func visit(_ command: RequestPairedClientSlots) async throws -> Response { nil }
    
    func visit(_ command: RequestPairedClientDetails) async throws -> Response { nil }
    
    func visit(_ command: RequestNickname) async throws -> Response { nil }
    
    func visit(_ command: UpdateNickname) async throws -> Response {
        return DeviceNicknameNotification(
            deviceId: command.deviceId,
            clientSlot: clientSlot,
            nickname: command.nickname
        )
    }
    
    func visit(_ command: RequestState) async throws -> Response {
        let newRunningState: RunningState
        let newSecondsRemaining: Int
        
        let decrementedTimeRemaining = max(0, mockDevice.secondsRemaining - 1)

        switch mockDevice.runningState {
        case .off:
            newRunningState = .off
            newSecondsRemaining = outlet0MaxDuration
        case .paused:
            newRunningState = mockDevice.secondsRemaining > 0 ? .paused : .off
            newSecondsRemaining = newRunningState == .paused ? decrementedTimeRemaining : outlet0MaxDuration
        case .running:
            newRunningState = mockDevice.secondsRemaining > 0 ? .running : .paused
            newSecondsRemaining = newRunningState == .running ? decrementedTimeRemaining : pauseTimerDurationSeconds
        case .cold:
            newRunningState = mockDevice.secondsRemaining > 0 ? .running : .paused
            newSecondsRemaining = newRunningState == .cold ? decrementedTimeRemaining : pauseTimerDurationSeconds
        }

        return DeviceStateNotification(
            deviceId: command.deviceId,
            clientSlot: clientSlot,
            targetTemperature: mockDevice.targetTemperature,
            actualTemperature: mockDevice.actualTemperature,
            outletSlot0IsRunning: newRunningState == .running ? mockDevice.getOutletBySlot(outletSlot: Outlet.outletSlot0)?.isRunning ?? false : false,
            outletSlot1IsRunning: newRunningState == .running ? mockDevice.getOutletBySlot(outletSlot: Outlet.outletSlot1)?.isRunning ?? false : false,
            secondsRemaining: newSecondsRemaining,
            runningState: newRunningState
        )
    }
    
    func visit(_ command: RequestDeviceSettings) async throws -> Response { nil }
    
    func visit(_ command: UpdateDefaultPresetSlot) async throws -> Response {
        return DeviceSettingsNotification(
            deviceId: command.deviceId,
            clientSlot: clientSlot,
            defaultPresetSlot: command.presetSlot,
            standbyLightingEnabled: mockDevice.standbyLightingEnabled,
            outletsSwitched: mockDevice.outletsSwitched,
            wirelessRemoteButtonOutletSlotsEnabled: mockDevice.outletSlotsEnabledForWirelessRemoteButton
        )
    }
    
    func visit(_ command: UpdateControllerSettings) async throws -> Response {
        return DeviceSettingsNotification(
            deviceId: command.deviceId,
            clientSlot: clientSlot,
            defaultPresetSlot: mockDevice.defaultPresetSlot ?? 0,
            standbyLightingEnabled: command.standbyLightingEnabled,
            outletsSwitched: command.outletsSwitched,
            wirelessRemoteButtonOutletSlotsEnabled: mockDevice.outletSlotsEnabledForWirelessRemoteButton
        )
    }
    
    func visit(_ command: RequestPresetSlots) async throws -> Response { nil }
    
    func visit(_ command: RequestPresetDetails) async throws -> Response { nil }
    
    func visit(_ command: UpdatePresetDetails) async throws -> Response {
        return PresetDetailsNotification(
            deviceId: command.deviceId,
            clientSlot: clientSlot,
            presetSlot: command.presetSlot,
            name: command.name,
            outletSlot: command.outletSlot,
            targetTemperature: command.targetTemperature,
            durationSeconds: command.durationSeconds
        )
    }
    
    func visit(_ command: DeletePresetDetails) async throws -> Response {
        return PresetSlotsNotification(
            deviceId: command.deviceId,
            clientSlot: clientSlot,
            presetSlots: mockDevice.presets.map(\.presetSlot).filter({ $0 != command.presetSlot })
        )
    }
    
    func visit(_ command: StartPreset) async throws -> Response {
        if let preset = mockDevice.getPresetBySlot(command.presetSlot) {
            return ControlsOperatedNotification(
                deviceId: command.deviceId,
                clientSlot: clientSlot,
                selectedTemperature: nil,
                targetTemperature: preset.targetTemperature,
                actualTemperature: mockDevice.actualTemperature,
                outletSlot0IsRunning: false,
                outletSlot1IsRunning: true,
                secondsRemaining: preset.durationSeconds,
                runningState: .running
            )
        } else {
            return nil
        }
    }
    
    func visit(_ command: OperateOutletControls) async throws -> Response {
        
        let newSecondsRemaining: Int
        if (command.runningState != mockDevice.runningState) {
            switch command.runningState {
            case .off, .running, .cold:
                newSecondsRemaining = outlet0MaxDuration
            case .paused:
                newSecondsRemaining = pauseTimerDurationSeconds
            }
        } else {
            newSecondsRemaining = mockDevice.secondsRemaining
        }
        
        return ControlsOperatedNotification(
            deviceId: command.deviceId,
            clientSlot: clientSlot,
            selectedTemperature: command.targetTemperature,
            targetTemperature: command.targetTemperature,
            actualTemperature: mockDevice.actualTemperature,
            outletSlot0IsRunning: command.outletSlot0Running,
            outletSlot1IsRunning: command.outletSlot1Running,
            secondsRemaining: newSecondsRemaining,
            runningState: command.runningState
        )
    }
    
    func visit(_ command: RequestOutletSettings) async throws -> Response { nil }
    
    func visit(_ command: UpdateOutletSettings) async throws -> Response {
        return OutletSettingsNotification(
            deviceId: command.deviceId,
            clientSlot: clientSlot,
            outletSlot: command.outletSlot,
            minimumTemperature: command.minimumTemperature,
            maximumTemperature: command.maximumTemperature,
            maximumDurationSeconds: command.maximumDurationSeconds
        )
    }
    
    func visit(_ command: UpdateWirelessRemoteButtonSettings) async throws -> Response {
        return DeviceSettingsNotification(
            deviceId: command.deviceId,
            clientSlot: clientSlot,
            defaultPresetSlot: mockDevice.defaultPresetSlot ?? 0,
            standbyLightingEnabled: mockDevice.standbyLightingEnabled,
            outletsSwitched: mockDevice.outletsSwitched,
            wirelessRemoteButtonOutletSlotsEnabled: command.outletSlotsEnabled
        )
    }
    
    func visit(_ command: RestartDevice) async throws -> Response { nil }
    
    func visit(_ command: FactoryResetDevice) async throws -> Response {
        // This requires all settings & presets to revert to default
        return nil
    }
    
    func visit(_ command: RequestTechnicalInformation) async throws -> Response { nil }
    
    func visit(_ command: UnknownRequestTechnicalInformation) async throws -> Response { nil }
    
    func visit(_ command: UnknownCommand) async throws -> Response { nil }
}

