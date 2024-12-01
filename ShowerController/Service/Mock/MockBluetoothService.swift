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
    private static let author = "MockBluetoothService"

    nonisolated let modelExecutor: any ModelExecutor
    nonisolated let modelContainer: ModelContainer

    private let mockPeripherals: MockPeripherals

    init(modelContainer: ModelContainer, mockPeripherals: MockPeripherals) {
        let modelContext = ModelContext(modelContainer)
        modelContext.author = Self.author
        
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
        self.modelContainer = modelContainer
        
        self.mockPeripherals = mockPeripherals
    }
    
    func executeCommand(_ command: any DeviceCommand) async throws -> any DeviceNotification {
        return try await mockPeripherals.executeCommand(command)
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
        
        for (uuid, name) in try await mockPeripherals.getPeripheralSummary() {
            try self.modelContext.transaction {
                modelContext.insert(ScanResult(id: uuid, name: name))
            }
        }
    }
    
    func stopScan() async throws {
        // nothing to do
    }
}

actor MockPeripherals: ModelActor {
    private static let author = "MockDevices"
    
    nonisolated let modelExecutor: any ModelExecutor
    nonisolated let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) throws {
        let modelContext = ModelContext(modelContainer)
        modelContext.author = Self.author
        
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
        self.modelContainer = modelContainer
        

        let showerOutlet = Outlet(outletSlot: Outlet.outletSlot0, type: .overhead)
        let singleShower = Device(
            id: UUID(),
            name: "Single Shower",
            clientSlot: 0,
            outlets: [showerOutlet],
            pairedClients: [
                PairedClient(clientSlot: 0, name: "Client 0"),
                PairedClient(clientSlot: 1, name: "Client 1"),
                PairedClient(clientSlot: 2, name: "Client 2")
            ],
            technicalInformation: TechnicalInformation(valveType: 33, valveSoftwareVersion: 8, bluetoothType: 45, bluetoothSoftwareVersion: 4),
            userInterface: UserInterface(
                type: 999,
                softwareVersion: 1,
                buttons: [
                    UserInterfaceButton(
                        buttonSlot: UserInterfaceButton.buttonSlot0,
                        display: .power,
                        start: .outlet,
                        outlet: showerOutlet
                    )
                ]
            ),
            actualTemperature: 0,
            secondsRemaining: Device.maximumPermittedDurationSeconds
        )
        
        let dualShowerOutlet0 = Outlet(outletSlot: Outlet.outletSlot0, type: .overhead)
        let dualShowerOutlet1 = Outlet(outletSlot: Outlet.outletSlot1, type: .handset)
        let dualShower = Device(
            id: UUID(),
            name: "Dual Shower",
            clientSlot: 1,
            outlets: [dualShowerOutlet0, dualShowerOutlet1],
            pairedClients: [
                PairedClient(clientSlot: 0, name: "Client 0"),
                PairedClient(clientSlot: 1, name: "Client 1"),
                PairedClient(clientSlot: 2, name: "Client 2")
            ],
            technicalInformation: TechnicalInformation(valveType: 33, valveSoftwareVersion: 8, bluetoothType: 45, bluetoothSoftwareVersion: 4),
            userInterface: UserInterface(
                type: ProtocolConstants.uiTypeDualShower,
                softwareVersion: 1,
                buttons: [
                    UserInterfaceButton(
                        buttonSlot: UserInterfaceButton.buttonSlot0,
                        display: .outlet,
                        start: .outlet,
                        outlet: dualShowerOutlet0
                    ),
                    UserInterfaceButton(
                        buttonSlot: UserInterfaceButton.buttonSlot1,
                        display: .outlet,
                        start: .outlet,
                        outlet: dualShowerOutlet1
                    )
                ]
            ),
            actualTemperature: 0,
            secondsRemaining: Device.maximumPermittedDurationSeconds
        )
        
        let showerPlusBathOutlet0 = Outlet(outletSlot: Outlet.outletSlot0, type: .overhead)
        let showerPlusBathOutlet1 = Outlet(outletSlot: Outlet.outletSlot1, type: .bath)
        let showerPlusBath = Device(
            id: UUID(),
            name: "Shower plus Bath",
            clientSlot: 2,
            outlets: [showerPlusBathOutlet0, showerPlusBathOutlet1],
            presets: [
                Preset(presetSlot: 0, name: "Warm One", outlet: showerPlusBathOutlet1, targetTemperature: 45, durationSeconds: 1220),
                Preset(presetSlot: 1, name: "Short Run", outlet: showerPlusBathOutlet0, targetTemperature: 42, durationSeconds: 10)
            ],
            defaultPresetSlot: 0,
            pairedClients: [
                PairedClient(clientSlot: 0, name: "Client 0"),
                PairedClient(clientSlot: 1, name: "Client 1"),
                PairedClient(clientSlot: 2, name: "Client 2")
            ],
            technicalInformation: TechnicalInformation(valveType: 33, valveSoftwareVersion: 8, bluetoothType: 45, bluetoothSoftwareVersion: 4),
            userInterface: UserInterface(
                type: ProtocolConstants.uiTypeShowerPlusBath,
                softwareVersion: 1,
                buttons: [
                    UserInterfaceButton(
                        buttonSlot: UserInterfaceButton.buttonSlot0,
                        display: .outlet,
                        start: .outlet,
                        outlet: showerPlusBathOutlet0
                    ),
                    UserInterfaceButton(
                        buttonSlot: UserInterfaceButton.buttonSlot1,
                        display: .outlet,
                        start: .preset,
                        outlet: showerPlusBathOutlet1
                    )
                ]
            ),
            actualTemperature: 0,
            secondsRemaining: Device.maximumPermittedDurationSeconds
        )

        let bathOutlet = Outlet(outletSlot: Outlet.outletSlot0, type: .bath)
        let bath = Device(
            id: UUID(),
            name: "Bath",
            clientSlot: 0,
            outlets: [bathOutlet],
            presets: [
                Preset(presetSlot: 0, name: "Warm One", outlet: bathOutlet, targetTemperature: 45, durationSeconds: 1220),
                Preset(presetSlot: 1, name: "Short Run", outlet: bathOutlet, targetTemperature: 42, durationSeconds: 10)
            ],
            defaultPresetSlot: 0,
            pairedClients: [
                PairedClient(clientSlot: 0, name: "Client 0"),
                PairedClient(clientSlot: 1, name: "Client 1"),
                PairedClient(clientSlot: 2, name: "Client 2")
            ],
            technicalInformation: TechnicalInformation(valveType: 33, valveSoftwareVersion: 8, bluetoothType: 45, bluetoothSoftwareVersion: 4),
            userInterface: UserInterface(
                type: 999,
                softwareVersion: ProtocolConstants.uiTypeBath,
                buttons: [
                    UserInterfaceButton(
                        buttonSlot: UserInterfaceButton.buttonSlot0,
                        display: .power,
                        start: .outlet,
                        outlet: bathOutlet
                    )
                ]
            ),
            actualTemperature: 0,
            secondsRemaining: Device.maximumPermittedDurationSeconds
        )

        try modelContext.transaction {
            modelContext.insert(singleShower)
            modelContext.insert(dualShower)
            modelContext.insert(showerPlusBath)
            modelContext.insert(bath)
        }
    }
    
    private func findById(_ id: UUID) throws -> Device? {
        let findById = FetchDescriptor<Device>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(findById).first
    }
    
    func getPeripheralSummary() throws -> [(UUID, String)] {
        return try modelContext.fetch(FetchDescriptor<Device>(sortBy: [SortDescriptor(\.name)]))
            .map({ ($0.id, $0.name) })
    }

    func executeCommand(_ command: DeviceCommand) async throws -> DeviceNotification {
        if let mockPeripheral = try findById(command.deviceId) {
            if let mutation = try await command.accept(isolation: self, MockPeripheralMuationGenerator(mockDevice: mockPeripheral)) {
                let applier = DeviceNotificatonApplier(device: mockPeripheral, modelContext: modelContext)
                try modelContext.transaction {
                    mutation.accept(applier)
                }
            }
            
            return try await command.accept(isolation: self, MockDeviceNotificationGenerator(mockDevice: mockPeripheral))
        } else {
            throw BluetoothServiceError.peripheralNotFound
        }
    }
}

class MockPeripheralMuationGenerator: DeviceCommandVisitor {
    typealias Response = DeviceNotification?
    
    private let pauseTimerDurationSeconds = 300

    private let mockDevice: Device
    
    var outlet0MaxDuration: Int {
        mockDevice.getOutletBySlot(Outlet.outletSlot0)?.maximumDurationSeconds ?? 1800
    }

    init(mockDevice: Device) {
        self.mockDevice = mockDevice
    }


    func visit(isolation: isolated (any Actor)?, _ command: PairDevice) async throws -> Response {
        nil
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: UnpairDevice) async throws -> Response {
        nil
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestPairedClientSlots) async throws -> Response {
        nil
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestPairedClientDetails) async throws -> Response {
        nil
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestDeviceInformation) async throws -> Response {
        nil
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestNickname) async throws -> Response {
        nil
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: UpdateNickname) async throws -> Response {
        DeviceNicknameNotification(
            deviceId: mockDevice.id,
            nickname: command.nickname
        )
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestState) async throws -> Response {
        let newRunningState: Device.RunningState
        let newSecondsRemaining: Int

        let decrementedTimeRemaining = max(0, mockDevice.secondsRemaining - 1)

        switch mockDevice.runningState {
        case .off:
            newRunningState = .off
            newSecondsRemaining = outlet0MaxDuration
        case .paused:
            newRunningState = decrementedTimeRemaining > 0 ? .paused : .off
            newSecondsRemaining = decrementedTimeRemaining > 0 ? decrementedTimeRemaining : outlet0MaxDuration
        case .running, .cold:
            newRunningState = decrementedTimeRemaining > 0 ? mockDevice.runningState : .paused
            newSecondsRemaining = decrementedTimeRemaining > 0 ? decrementedTimeRemaining : pauseTimerDurationSeconds
        }
        
        let isFlowing = newRunningState == .running || newRunningState == .cold

        return DeviceStateNotification(
            deviceId: mockDevice.id,
            targetTemperature: mockDevice.targetTemperature,
            actualTemperature: mockDevice.actualTemperature,
            outletSlot0IsRunning: isFlowing ? mockDevice.isOutletRunning(outletSlot: Outlet.outletSlot0) : false,
            outletSlot1IsRunning: isFlowing ? mockDevice.isOutletRunning(outletSlot: Outlet.outletSlot1) : false,
            secondsRemaining: newSecondsRemaining,
            runningState: newRunningState
        )
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestDeviceSettings) async throws -> Response {
        nil
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: UpdateDefaultPresetSlot) async throws -> Response {
        DeviceSettingsNotification(
            deviceId: mockDevice.id,
            defaultPresetSlot: command.presetSlot,
            standbyLightingEnabled: mockDevice.standbyLightingEnabled,
            outletsSwitched: mockDevice.outletsSwitched,
            wirelessRemoteButtonOutletSlotsEnabled: mockDevice.outletSlotsEnabledForWirelessRemoteButton
        )
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: UpdateControllerSettings) async throws -> Response {
        DeviceSettingsNotification(
            deviceId: mockDevice.id,
            defaultPresetSlot: mockDevice.defaultPresetSlot ?? 0,
            standbyLightingEnabled: command.standbyLightingEnabled,
            outletsSwitched: command.outletsSwitched,
            wirelessRemoteButtonOutletSlotsEnabled: mockDevice.outletSlotsEnabledForWirelessRemoteButton
        )
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestPresetSlots) async throws -> Response {
        nil
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestPresetDetails) async throws -> Response {
        nil
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: UpdatePresetDetails) async throws -> Response {
        PresetDetailsNotification(
            deviceId: mockDevice.id,
            presetSlot: command.presetSlot,
            name: command.name,
            outletSlot: command.outletSlot,
            targetTemperature: command.targetTemperature,
            durationSeconds: command.durationSeconds
        )
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: DeletePresetDetails) async throws -> Response {
        PresetSlotsNotification(
            deviceId: mockDevice.id,
            presetSlots: mockDevice.presets.map(\.presetSlot).filter({ $0 != command.presetSlot })
        )
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: StartPreset) async throws -> Response {
        if let preset = mockDevice.getPresetBySlot(command.presetSlot) {
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
        } else {
            nil
        }
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: OperateOutletControls) async throws -> Response {
        let newSecondsRemaining = switch command.runningState {
        case .off:
            outlet0MaxDuration
        case .paused:
            switch mockDevice.runningState {
            case .paused:
                mockDevice.secondsRemaining
            default:
                pauseTimerDurationSeconds
            }
        case .running, .cold:
            switch mockDevice.runningState {
            case .running, .cold:
                mockDevice.secondsRemaining
            default:
                outlet0MaxDuration
            }
        }
        
        return ControlsOperatedNotification(
            deviceId: mockDevice.id,
            selectedTemperature: command.targetTemperature,
            targetTemperature: command.targetTemperature,
            actualTemperature: mockDevice.actualTemperature,
            outletSlot0IsRunning: command.outletSlot0Running,
            outletSlot1IsRunning: command.outletSlot1Running,
            secondsRemaining: newSecondsRemaining,
            runningState: command.runningState
        )
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestOutletSettings) async throws -> Response {
        nil
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: UpdateOutletSettings) async throws -> Response {
        OutletSettingsNotification(
            deviceId: mockDevice.id,
            outletSlot: command.outletSlot,
            maximumDurationSeconds: command.maximumDurationSeconds,
            maximumTemperature: command.maximumTemperature,
            minimumTemperature: command.minimumTemperature,
            thresholdTemperature: command.thresholdTemperature
        )
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: UpdateWirelessRemoteButtonSettings) async throws -> Response {
        DeviceSettingsNotification(
            deviceId: mockDevice.id,
            defaultPresetSlot: mockDevice.defaultPresetSlot ?? 0,
            standbyLightingEnabled: mockDevice.standbyLightingEnabled,
            outletsSwitched: mockDevice.outletsSwitched,
            wirelessRemoteButtonOutletSlotsEnabled: command.outletSlotsEnabled
        )
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RestartDevice) async throws -> Response {
        nil
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: FactoryResetDevice) async throws -> Response {
        nil
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestTechnicalInformation) async throws -> Response {
        nil
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: UnknownRequestTechnicalInformation) async throws -> Response {
        nil
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: UnknownCommand) async throws -> Response {
        nil
    }
    
}

class MockDeviceNotificationGenerator: DeviceCommandVisitor {
    typealias Response = DeviceNotification

    private var mockDevice: Device
    
    init(mockDevice: Device) {
        self.mockDevice = mockDevice
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: PairDevice) async throws -> Response {
        return PairSuccessNotification(
            deviceId: mockDevice.id,
            clientSlot: mockDevice.clientSlot,
            name: mockDevice.name
        )
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: UnpairDevice) async throws -> Response {
        return UnpairSuccessNotification(
            deviceId: mockDevice.id,
            clientSlot: mockDevice.clientSlot
        )
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestPairedClientSlots) async throws -> Response {
        return PairedClientSlotsNotification(
            deviceId: mockDevice.id,
            pairedClientSlots: mockDevice.pairedClients.map(\.clientSlot)
        )
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestPairedClientDetails) async throws -> Response {
        return PairedClientDetailsNotification(
            deviceId: mockDevice.id,
            pairedClientSlot: command.pairedClientSlot,
            name: mockDevice.pairedClients.first(where: { $0.clientSlot == command.pairedClientSlot})?.name
        )
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestDeviceInformation) async throws -> any Response {
        return DeviceInformationNotification(
            deviceId: mockDevice.id,
            manufacturerName: "Mr Shower",
            modelNumber: "NSx2",
            hardwareRevision: "1001",
            firmwareRevision: "2001",
            serialNumber: "3001"
        )
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestNickname) async throws -> Response {
        return DeviceNicknameNotification(
            deviceId: mockDevice.id,
            nickname: mockDevice.nickname
        )
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: UpdateNickname) async throws -> Response {
        return SuccessNotification(deviceId: command.deviceId)
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestState) async throws -> Response {
        return DeviceStateNotification(
            deviceId: mockDevice.id,
            targetTemperature: mockDevice.targetTemperature,
            actualTemperature: mockDevice.actualTemperature,
            outletSlot0IsRunning: mockDevice.isOutletRunning(outletSlot: Outlet.outletSlot0),
            outletSlot1IsRunning: mockDevice.isOutletRunning(outletSlot: Outlet.outletSlot1),
            secondsRemaining: mockDevice.secondsRemaining,
            runningState: mockDevice.runningState
        )
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestDeviceSettings) async throws -> Response {
        return DeviceSettingsNotification(
            deviceId: mockDevice.id,
            defaultPresetSlot: mockDevice.defaultPresetSlot ?? 0,
            standbyLightingEnabled: mockDevice.standbyLightingEnabled,
            outletsSwitched: mockDevice.outletsSwitched,
            wirelessRemoteButtonOutletSlotsEnabled: mockDevice.outletSlotsEnabledForWirelessRemoteButton
        )
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: UpdateDefaultPresetSlot) async throws -> Response {
        return SuccessNotification(deviceId: command.deviceId)
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: UpdateControllerSettings) async throws -> Response {
        return SuccessNotification(deviceId: command.deviceId)
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestPresetSlots) async throws -> Response {
        return PresetSlotsNotification(
            deviceId: mockDevice.id,
            presetSlots: mockDevice.presets.map(\.presetSlot)
        )
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestPresetDetails) async throws -> Response {
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
    
    func visit(isolation: isolated (any Actor)?, _ command: UpdatePresetDetails) async throws -> Response {
        return SuccessNotification(deviceId: mockDevice.id)
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: DeletePresetDetails) async throws -> Response {
        return SuccessNotification(deviceId: mockDevice.id)
    }
    
    private func currentControlsOperated() -> ControlsOperatedNotification {
        return ControlsOperatedNotification(
            deviceId: mockDevice.id,
            selectedTemperature: mockDevice.selectedTemperature,
            targetTemperature: mockDevice.targetTemperature,
            actualTemperature: mockDevice.actualTemperature,
            outletSlot0IsRunning: mockDevice.getOutletBySlot(Outlet.outletSlot0)?.isRunning ?? false,
            outletSlot1IsRunning: mockDevice.getOutletBySlot(Outlet.outletSlot1)?.isRunning ?? false,
            secondsRemaining: mockDevice.secondsRemaining,
            runningState: mockDevice.runningState
        )
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: StartPreset) async throws -> Response {
        return currentControlsOperated()
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: OperateOutletControls) async throws -> Response {
        return currentControlsOperated()

    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestOutletSettings) async throws -> Response {
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
    
    func visit(isolation: isolated (any Actor)?, _ command: UpdateOutletSettings) async throws -> Response {
        if let _ = mockDevice.getOutletBySlot(command.outletSlot) {
            return SuccessNotification(deviceId: mockDevice.id)
        } else {
            return FailedNotification(deviceId: mockDevice.id)
        }
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: UpdateWirelessRemoteButtonSettings) async throws -> Response {
        return SuccessNotification(deviceId: mockDevice.id)
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RestartDevice) async throws -> Response {
        return SuccessNotification(deviceId: mockDevice.id)
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: FactoryResetDevice) async throws -> Response {
        // This requires all settings & presets to revert to default
        return SuccessNotification(deviceId: mockDevice.id)
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: RequestTechnicalInformation) async throws -> Response {
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
    
    func visit(isolation: isolated (any Actor)?, _ command: UnknownRequestTechnicalInformation) async throws -> Response {
        return UnknownNotification(deviceId: mockDevice.id)
    }
    
    func visit(isolation: isolated (any Actor)?, _ command: UnknownCommand) async throws -> Response {
        return UnknownNotification(deviceId: mockDevice.id)
    }
}
