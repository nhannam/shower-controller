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
    struct MockDeviceConfig {
        let name: String
        let uiType: UInt16
    }
    static let mockConfig: [UUID:MockDeviceConfig] = [
        UUID(): MockDeviceConfig(name: "Single Shower", uiType: 999),
        UUID(): MockDeviceConfig(name: "Dual Shower", uiType: ProtocolConstants.uiTypeDualShower),
        UUID(): MockDeviceConfig(name: "Shower plus Bath", uiType: ProtocolConstants.uiTypeShowerPlusBath),
        UUID(): MockDeviceConfig(name: "Bath", uiType: ProtocolConstants.uiTypeBath)
    ]
    
    private static let author = "MockBluetoothService"

    nonisolated let modelExecutor: any ModelExecutor
    nonisolated let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        let modelContext = ModelContext(modelContainer)
        modelContext.author = Self.author
        
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
        self.modelContainer = modelContainer
    }
    
    func executeCommand(_ command: any DeviceCommand) async throws -> any DeviceNotification {
        if command is PairDevice {
            if let mockConfig = Self.mockConfig[command.deviceId] {
                return PairSuccessNotification(deviceId: command.deviceId, clientSlot: 1, name: mockConfig.name)
            } else {
                return FailedNotification(deviceId: command.deviceId)
            }
        }
        
        let deviceActor = try MockDeviceActor(modelContainer: modelContainer, deviceId: command.deviceId)
        return try await deviceActor.executeCommand(command)
    }
    
    func disconnectAll() async throws {
        // Nothing to do
    }
    
    func disconnect(_ deviceId: UUID) async throws {
        // Nothing to do
    }
    
    func startScan() async throws {
        try self.modelContext.transaction {
            try modelContext.delete(model: ScanResult.self)
        }
        
        try await Task.sleep(for: .milliseconds(500))
        
        try self.modelContext.transaction {
            for mockConfig in MockBluetoothService.mockConfig {
                modelContext.insert(ScanResult(id: mockConfig.key, name: mockConfig.value.name))
            }
        }
    }
    
    func stopScan() async throws {
        // nothing to do
    }
}

actor MockDeviceActor: SwiftData.ModelActor, DeviceCommandVisitor {
    typealias Response = DeviceNotification

    private static let author = "MockDeviceActor"

    nonisolated let modelExecutor: any SwiftData.ModelExecutor
    nonisolated let modelContainer: SwiftData.ModelContainer
    private let pauseTimerDurationSeconds = 300

    let mockDevice: Device
    
    var outlet0MaxDuration: Int {
        mockDevice.getOutletBySlot(Outlet.outletSlot0)?.maximumDurationSeconds ?? 1800
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
            throw BluetoothServiceError.internalError
        }
    }
    
    func executeCommand(_ command: DeviceCommand) async throws -> DeviceNotification {
        guard (command.deviceId == mockDevice.id) else {
            throw BluetoothServiceError.internalError
        }
        
        return try await command.accept(self)
    }
    
    private func applyToMockDevice(_ notifications: DeviceNotification...) throws {
        try modelContext.transaction {
            for notification in notifications {
                notification.accept(DeviceNotificatonApplier(device: mockDevice, modelContext: modelContext))
            }
        }
    }
    
    func visit(_ command: PairDevice) async throws -> Response {
        return PairSuccessNotification(
            deviceId: mockDevice.id,
            clientSlot: mockDevice.clientSlot,
            name: mockDevice.name
        )
    }
    
    func visit(_ command: UnpairDevice) async throws -> Response {
        return UnpairSuccessNotification(
            deviceId: mockDevice.id,
            clientSlot: mockDevice.clientSlot
        )
    }
    
    func visit(_ command: RequestPairedClientSlots) async throws -> Response {
        if mockDevice.pairedClients.isEmpty {
            try applyToMockDevice(
                PairedClientSlotsNotification(
                    deviceId: mockDevice.id,
                    pairedClientSlots: [ 0, 1 ]
                ),
                PairedClientDetailsNotification(
                    deviceId: mockDevice.id,
                    pairedClientSlot: 0,
                    name: "Paired Client 0"
                ),
                PairedClientDetailsNotification(
                    deviceId: mockDevice.id,
                    pairedClientSlot: 1,
                    name: "Paired Client 1"
                )
            )
        }
        
        return PairedClientSlotsNotification(
            deviceId: mockDevice.id,
            pairedClientSlots: mockDevice.pairedClients.map(\.clientSlot)
        )
    }
    
    func visit(_ command: RequestPairedClientDetails) async throws -> Response {
        return PairedClientDetailsNotification(
            deviceId: mockDevice.id,
            pairedClientSlot: command.pairedClientSlot,
            name: mockDevice.pairedClients.first(where: { $0.clientSlot == command.pairedClientSlot})?.name
        )
    }
    
    func visit(_ command: RequestDeviceInformation) async throws -> any Response {
        return DeviceInformationNotification(
            deviceId: mockDevice.id,
            manufacturerName: "Mr Shower",
            modelNumber: "NSx2",
            hardwareRevision: "1001",
            firmwareRevision: "2001",
            serialNumber: "3001"
        )
    }
    
    func visit(_ command: RequestNickname) async throws -> Response {
        return DeviceNicknameNotification(
            deviceId: mockDevice.id,
            nickname: mockDevice.nickname
        )
    }
    
    func visit(_ command: UpdateNickname) async throws -> Response {
        try applyToMockDevice(
            DeviceNicknameNotification(
                deviceId: mockDevice.id,
                nickname: command.nickname
            )
        )
        return SuccessNotification(deviceId: command.deviceId)
    }
    
    func visit(_ command: RequestState) async throws -> Response {
        let newRunningState: Device.RunningState
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
            deviceId: mockDevice.id,
            targetTemperature: mockDevice.targetTemperature,
            actualTemperature: mockDevice.actualTemperature,
            outletSlot0IsRunning: newRunningState == .running ? mockDevice.isOutletRunning(outletSlot: Outlet.outletSlot0) : false,
            outletSlot1IsRunning: newRunningState == .running ? mockDevice.isOutletRunning(outletSlot: Outlet.outletSlot1) : false,
            secondsRemaining: newSecondsRemaining,
            runningState: newRunningState
        )
    }
    
    func visit(_ command: RequestDeviceSettings) async throws -> Response {
        return DeviceSettingsNotification(
            deviceId: mockDevice.id,
            defaultPresetSlot: mockDevice.defaultPresetSlot ?? 0,
            standbyLightingEnabled: mockDevice.standbyLightingEnabled,
            outletsSwitched: mockDevice.outletsSwitched,
            wirelessRemoteButtonOutletSlotsEnabled: mockDevice.outletSlotsEnabledForWirelessRemoteButton
        )
    }
    
    func visit(_ command: UpdateDefaultPresetSlot) async throws -> Response {
        try applyToMockDevice(
            DeviceSettingsNotification(
                deviceId: mockDevice.id,
                defaultPresetSlot: command.presetSlot,
                standbyLightingEnabled: mockDevice.standbyLightingEnabled,
                outletsSwitched: mockDevice.outletsSwitched,
                wirelessRemoteButtonOutletSlotsEnabled: mockDevice.outletSlotsEnabledForWirelessRemoteButton
            )
        )
        return SuccessNotification(deviceId: command.deviceId)
    }
    
    func visit(_ command: UpdateControllerSettings) async throws -> Response {
        try applyToMockDevice(
            DeviceSettingsNotification(
                deviceId: mockDevice.id,
                defaultPresetSlot: mockDevice.defaultPresetSlot ?? 0,
                standbyLightingEnabled: command.standbyLightingEnabled,
                outletsSwitched: command.outletsSwitched,
                wirelessRemoteButtonOutletSlotsEnabled: mockDevice.outletSlotsEnabledForWirelessRemoteButton
            )
        )
        return SuccessNotification(deviceId: command.deviceId)
    }
    
    func visit(_ command: RequestPresetSlots) async throws -> Response {
        if mockDevice.presets.isEmpty {
            let firstOutlet = mockDevice.outletsSortedBySlot.first!
            let lastOutlet = mockDevice.outletsSortedBySlot.last!
            try applyToMockDevice(
                PresetSlotsNotification(
                    deviceId: mockDevice.id,
                    presetSlots: [ 0, 1 ]
                ),
                PresetDetailsNotification(
                    deviceId: mockDevice.id,
                    presetSlot: 0,
                    name: "Warm One",
                    outletSlot: lastOutlet.outletSlot,
                    targetTemperature: 45,
                    durationSeconds: 1220
                ),
                PresetDetailsNotification(
                    deviceId: mockDevice.id,
                    presetSlot: 1,
                    name: "Short Run",
                    outletSlot: firstOutlet.outletSlot,
                    targetTemperature: 42,
                    durationSeconds: 10
                ),
                DeviceSettingsNotification(
                    deviceId: mockDevice.id,
                    defaultPresetSlot: 0,
                    standbyLightingEnabled: true,
                    outletsSwitched: false,
                    wirelessRemoteButtonOutletSlotsEnabled: [ firstOutlet.outletSlot ]
                )
            )
        }

        return PresetSlotsNotification(
            deviceId: mockDevice.id,
            presetSlots: mockDevice.presets.map(\.presetSlot)
        )
    }
    
    func visit(_ command: RequestPresetDetails) async throws -> Response {
        if let preset = mockDevice.getPresetBySlot(command.presetSlot) {
            return PresetDetailsNotification(
                deviceId: mockDevice.id,
                presetSlot: command.presetSlot,
                name: preset.name,
                outletSlot: preset.outlet.outletSlot,
                targetTemperature: preset.targetTemperature,
                durationSeconds: preset.durationSeconds
            )
        } else {
            return FailedNotification(deviceId: mockDevice.id)
        }
    }
    
    func visit(_ command: UpdatePresetDetails) async throws -> Response {
        try applyToMockDevice(
            PresetDetailsNotification(
                deviceId: mockDevice.id,
                presetSlot: command.presetSlot,
                name: command.name,
                outletSlot: command.outletSlot,
                targetTemperature: command.targetTemperature,
                durationSeconds: command.durationSeconds
            )
        )
        return SuccessNotification(deviceId: mockDevice.id)
    }
    
    func visit(_ command: DeletePresetDetails) async throws -> Response {
        try applyToMockDevice(
            PresetSlotsNotification(
                deviceId: mockDevice.id,
                presetSlots: mockDevice.presets.map(\.presetSlot).filter({ $0 != command.presetSlot })
            )
        )
        return SuccessNotification(deviceId: mockDevice.id)
    }
    
    private func currentControlsOperated() -> ControlsOperatedNotification {
        return ControlsOperatedNotification(
            deviceId: mockDevice.id,
            selectedTemperature: nil,
            targetTemperature: mockDevice.targetTemperature,
            actualTemperature: mockDevice.actualTemperature,
            outletSlot0IsRunning: mockDevice.getOutletBySlot(Outlet.outletSlot0)?.isRunning ?? false,
            outletSlot1IsRunning: mockDevice.getOutletBySlot(Outlet.outletSlot1)?.isRunning ?? false,
            secondsRemaining: mockDevice.secondsRemaining,
            runningState: mockDevice.runningState
        )
    }
    
    func visit(_ command: StartPreset) async throws -> Response {
        if let preset = mockDevice.getPresetBySlot(command.presetSlot) {
            try applyToMockDevice(
                ControlsOperatedNotification(
                    deviceId: mockDevice.id,
                    selectedTemperature: nil,
                    targetTemperature: preset.targetTemperature,
                    actualTemperature: mockDevice.actualTemperature,
                    outletSlot0IsRunning: preset.outlet.outletSlot == Outlet.outletSlot0,
                    outletSlot1IsRunning: preset.outlet.outletSlot == Outlet.outletSlot1,
                    secondsRemaining: preset.durationSeconds,
                    runningState: .running
                )
            )
        }
        
        return currentControlsOperated()
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
        
        try applyToMockDevice(
            ControlsOperatedNotification(
                deviceId: mockDevice.id,
                selectedTemperature: command.targetTemperature,
                targetTemperature: command.targetTemperature,
                actualTemperature: mockDevice.actualTemperature,
                outletSlot0IsRunning: command.outletSlot0Running,
                outletSlot1IsRunning: command.outletSlot1Running,
                secondsRemaining: newSecondsRemaining,
                runningState: command.runningState
            )
        )
        
        return currentControlsOperated()

    }
    
    func visit(_ command: RequestOutletSettings) async throws -> Response {
        if let outlet = mockDevice.getOutletBySlot(command.outletSlot) {
            return OutletSettingsNotification(
                deviceId: mockDevice.id,
                outletSlot: outlet.outletSlot,
                maximumDurationSeconds: outlet.maximumDurationSeconds,
                maximumTemperature: outlet.maximumTemperature,
                minimumTemperature: outlet.minimumTemperature,
                thresholdTemperature: outlet.thresholdTemperature
            )
        } else {
            return FailedNotification(deviceId: mockDevice.id)
        }
    }
    
    func visit(_ command: UpdateOutletSettings) async throws -> Response {
        if let _ = mockDevice.getOutletBySlot(command.outletSlot) {
            try applyToMockDevice(
                OutletSettingsNotification(
                    deviceId: mockDevice.id,
                    outletSlot: command.outletSlot,
                    maximumDurationSeconds: command.maximumDurationSeconds,
                    maximumTemperature: command.maximumTemperature,
                    minimumTemperature: command.minimumTemperature,
                    thresholdTemperature: command.thresholdTemperature
                )
            )
            return SuccessNotification(deviceId: mockDevice.id)
        } else {
            return FailedNotification(deviceId: mockDevice.id)
        }
    }
    
    func visit(_ command: UpdateWirelessRemoteButtonSettings) async throws -> Response {
        try applyToMockDevice(
            DeviceSettingsNotification(
                deviceId: mockDevice.id,
                defaultPresetSlot: mockDevice.defaultPresetSlot ?? 0,
                standbyLightingEnabled: mockDevice.standbyLightingEnabled,
                outletsSwitched: mockDevice.outletsSwitched,
                wirelessRemoteButtonOutletSlotsEnabled: command.outletSlotsEnabled
            )
        )
        return SuccessNotification(deviceId: mockDevice.id)
    }
    
    func visit(_ command: RestartDevice) async throws -> Response {
        return SuccessNotification(deviceId: mockDevice.id)
    }
    
    func visit(_ command: FactoryResetDevice) async throws -> Response {
        // This requires all settings & presets to revert to default
        return SuccessNotification(deviceId: mockDevice.id)
    }
    
    func visit(_ command: RequestTechnicalInformation) async throws -> Response {
        if mockDevice.technicalInformation == nil {
            if let mockConfig = MockBluetoothService.mockConfig[command.deviceId] {
                let (outlets, buttons) = Converter.outletsAndButtons(mockConfig.uiType)
                try applyToMockDevice(
                    TechnicalInformationNotification(
                        deviceId: mockDevice.id,
                        valve: TechnicalInformationNotification.Valve(
                            type: 33,
                            softwareVersion: 8,
                            outlets: outlets
                        ),
                        ui: TechnicalInformationNotification.UI(
                            type: mockConfig.uiType,
                            softwareVersion: 6,
                            buttons: buttons
                        ),
                        bluetooth: TechnicalInformationNotification.Bluetooth(type: 45, softwareVersion: 4)
                    )
                )
            }
        }
        
        if let technicalInformation = mockDevice.technicalInformation {
            return TechnicalInformationNotification(
                deviceId: mockDevice.id,
                valve: TechnicalInformationNotification.Valve(
                    type: technicalInformation.valveType,
                    softwareVersion: technicalInformation.valveSoftwareVersion,
                    outlets: mockDevice.outletsSortedBySlot.map({ outlet in
                        TechnicalInformationNotification.Valve.OutletSpec(
                            outletSlot: outlet.outletSlot,
                            type: outlet.type
                        )
                    })
                ),
                ui: TechnicalInformationNotification.UI(
                    type: mockDevice.userInterface!.type,
                    softwareVersion:  mockDevice.userInterface!.softwareVersion,
                    buttons: mockDevice.userInterface!.buttons.map({ button in
                        TechnicalInformationNotification.UI.ButtonSpec(
                            buttonSlot: button.buttonSlot,
                            display: button.display, start: button.start,
                            outletSlot: button.outlet.outletSlot
                        )
                    })
                ),
                bluetooth: TechnicalInformationNotification.Bluetooth(
                    type: technicalInformation.bluetoothType,
                    softwareVersion: technicalInformation.bluetoothSoftwareVersion
                )
            )
        } else {
            return FailedNotification(deviceId: command.deviceId)
        }
    }
    
    func visit(_ command: UnknownRequestTechnicalInformation) async throws -> Response {
        return UnknownNotification(deviceId: mockDevice.id)
    }
    
    func visit(_ command: UnknownCommand) async throws -> Response {
        return UnknownNotification(deviceId: mockDevice.id)
    }
}

