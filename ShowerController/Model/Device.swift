//
//  Device.swift
//  ShowerController
//
//  Created by Nigel Hannam on 23/10/2024.
//

import Foundation
import SwiftData
import CoreBluetooth

enum RunningState: String, Codable { case off, running, cold, paused }

@Model
class Device {
    static let durationSecondsSelectionSteps = 10
    static let temperatureSteps = 0.1
    private static let numberOfPresetSlots = UInt8(8)
    private static let outletsStoppedLockoutDuration: TimeInterval = TimeInterval(5)

    @Attribute(.unique)
    private(set) var id: UUID
    private(set)var name: String
    
    fileprivate(set) var nickname: String?
    var manufacturerName: String
    var modelNumber: String
    var hardwareRevision: String
    var firmwareRevision: String
    var serialNumber: String
    
    @Relationship(deleteRule: .cascade, inverse: \Outlet.device)
    fileprivate(set) var outlets: [Outlet]
    fileprivate(set) var outletsSwitched: Bool

    @Relationship(deleteRule: .cascade, inverse: \Preset.device)
    private(set) var presets: [Preset]
    fileprivate(set) var defaultPresetSlot: UInt8?

    fileprivate(set) var clientSlot: UInt8?
    @Relationship(deleteRule: .cascade, inverse: \PairedClient.device)
    private(set) var pairedClients: [PairedClient]
    
    @Relationship(deleteRule: .cascade, inverse: \TechnicalInformation.device)
    fileprivate(set) var technicalInformation: TechnicalInformation?
    
    fileprivate(set) var standbyLightingEnabled: Bool
    
    private(set) var runningState: RunningState
    fileprivate(set) var lastRunningStateReceived: Date
    
    private(set) var updatesLockedOutUntil: Date

    fileprivate(set) var selectedTemperature: Double

    fileprivate(set) var targetTemperature: Double
    fileprivate(set) var actualTemperature: Double
    fileprivate(set) var secondsRemaining: Int

    var displayName: String {
        nickname ?? name
    }
    
    var isStopped: Bool {
        runningState == .off
    }
    
    var outletSlotsEnabledForWirelessRemoteButton: [Int] {
        return outlets
            .filter({ $0.isEnabledForWirelessRemoteButton })
            .map(\.outletSlot)
    }
    
    var defaultPreset: Preset? {
        return presets
            .first(where: { $0.presetSlot == defaultPresetSlot })
    }

    init(
        id: UUID,
        name: String,
        nickname: String? = nil,
        manufacturerName: String = "",
        modelNumber: String = "",
        hardwareRevision: String = "",
        firmwareRevision: String = "",
        serialNumber: String = "",
        outlets: [Outlet] = [],
        outletsSwitched: Bool = false,
        presets: [Preset] = [],
        defaultPresetSlot: UInt8? = nil,
        clientSlot: UInt8? = nil,
        pairedClients: [PairedClient] = [],
        technicalInformation: TechnicalInformation? = nil,
        standbyLightingEnabled: Bool = true,
        runningState: RunningState = RunningState.off,
        lastRunningStateReceived: Date = Date.distantPast,
        updatesLockedOutUntil: Date = Date.distantPast,
        selectedTemperature: Double = 0,
        targetTemperature: Double = 0,
        actualTemperature: Double = 0,
        secondsRemaining: Int = 0
    ) {
        self.id = id
        self.name = name
        self.nickname = nickname
        self.manufacturerName = manufacturerName
        self.modelNumber = modelNumber
        self.hardwareRevision = hardwareRevision
        self.firmwareRevision = firmwareRevision
        self.serialNumber = serialNumber
        self.outlets = outlets
        self.outletsSwitched = outletsSwitched
        self.presets = presets
        self.defaultPresetSlot = defaultPresetSlot
        self.clientSlot = clientSlot
        self.pairedClients = pairedClients
        self.technicalInformation = technicalInformation
        self.standbyLightingEnabled = standbyLightingEnabled
        self.runningState = runningState
        self.lastRunningStateReceived = lastRunningStateReceived
        self.updatesLockedOutUntil = updatesLockedOutUntil
        self.selectedTemperature = selectedTemperature
        self.targetTemperature = targetTemperature
        self.actualTemperature = actualTemperature
        self.secondsRemaining = secondsRemaining
    }

    func getOutletBySlot(outletSlot: Int) -> Outlet? {
        return outlets.first(where: { $0.outletSlot == outletSlot })
    }

    func isOutletRunning(outletSlot: Int) -> Bool {
        return getOutletBySlot(outletSlot: outletSlot)?.isRunning ?? false
    }

    func getNextAvailablePresetSlot() -> UInt8? {
        let occupiedSlots = presets.map(\.presetSlot)
        return (UInt8(0)..<Device.numberOfPresetSlots)
            .first(where: { !occupiedSlots.contains($0) })
    }
    
    func getPresetBySlot(_ presetSlot: UInt8) -> Preset? {
        return presets.first(where: { $0.isSlot(presetSlot) })
    }

    fileprivate func addPreset(_ presetSlot: UInt8) -> Preset {
        if let existing = getPresetBySlot(presetSlot) {
            return existing
        }
        let preset = Preset(presetSlot: presetSlot, name: "", outlet: getOutletBySlot(outletSlot: Outlet.outletSlot1)!)
        presets.append(preset)
        return preset
    }

    fileprivate func removePresetBySlot(_ presetSlot: UInt8) -> Preset? {
        if let index = presets.firstIndex(where: { $0.isSlot(presetSlot) }) {
            let removed = presets[index]
            presets.remove(at: index)
            return removed
        } else {
            return nil
        }
    }

    func getPairedClientBySlot(_ clientSlot: UInt8) -> PairedClient? {
        return pairedClients.first(where: { $0.isSlot(clientSlot) })
    }

    fileprivate func addPairedClient(_ client: PairedClient) {
        guard getPairedClientBySlot(client.clientSlot) == nil else {
            return
        }
        pairedClients.append(client)
    }

    fileprivate func removePairedClientBySlot(_ clientSlot: UInt8) -> PairedClient? {
        if let index = pairedClients.firstIndex(where: { $0.isSlot(clientSlot) }) {
            let removed = pairedClients[index]
            pairedClients.remove(at: index)
            return removed
        } else {
            return nil
        }
    }
    
    func getRunningStateForTemperature(temperature: Double, outletSlot: Int) -> RunningState {
        if let outlet = getOutletBySlot(outletSlot: outletSlot) {
            outlet.isMinimumTemperature(temperature) ? .cold : .running
        } else {
            .running
        }
    }
    
    fileprivate func updateRunningState(_ newRunningState: RunningState) {
        let now = Date()
        
        if runningState != newRunningState {
            runningState = newRunningState
            
            // If it's a while since we had a state update, try to avoid locking the controls
            // out unecesarily.
            let isLastRunningStateReceivedRecent = now < lastRunningStateReceived + (2 * Self.outletsStoppedLockoutDuration)

            if newRunningState == .off && isLastRunningStateReceivedRecent  {
                updatesLockedOutUntil = Date() + Self.outletsStoppedLockoutDuration
            }
        }
        
        lastRunningStateReceived = now
    }
}

class DeviceNotificatonApplier: DeviceNotificationVisitor {
    private let device: Device
    private let modelContext: ModelContext
    
    init(device: Device, modelContext: ModelContext) {
        self.device = device
        self.modelContext = modelContext
    }
    
    func visit(_ notification: DeviceInformationNotification) {
        device.manufacturerName = notification.manufacturerName
        device.modelNumber = notification.modelNumber
        device.hardwareRevision = notification.hardwareRevision
        device.firmwareRevision = notification.firmwareRevision
        device.serialNumber = notification.serialNumber
    }
    
    func visit(_ notification: PairSuccessNotification) {
        device.clientSlot = notification.clientSlot
    }
    
    func visit(_ notification: UnpairSuccessNotification) {
        if let removed = device.removePairedClientBySlot(notification.clientSlot) {
            modelContext.delete(removed)
        }
        if (device.clientSlot == notification.clientSlot) {
            device.clientSlot = nil
        }
    }
    
    func visit(_ notification: SuccessNotification) {
        // Nothing to do - we make a separate request to fetch the updated state
    }
    
    func visit(_ notification: FailedNotification) {
        // Nothing to do
    }
    
    func visit(_ notification: PresetSlotsNotification) {
        let existingSlots = device.presets.map(\.presetSlot)
        let newSlots = notification.presetSlots
        
        if (newSlots != existingSlots) {
            let addedSlots = newSlots.filter({ newSlot in !existingSlots.contains(newSlot) })
            addedSlots.forEach({
                let _ = device.addPreset($0)
            })
            
            let removedSlots = existingSlots.filter({ existingSlot in !newSlots.contains(existingSlot) })
            removedSlots.forEach({
                if let removed = device.removePresetBySlot($0) {
                    // Always delete from the modelContext in addition to modifying the model
                    modelContext.delete(removed)
                }
            })
        }
    }

    func visit(_ notification: PresetDetailsNotification) {
        let preset = device.getPresetBySlot(notification.presetSlot) ?? device.addPreset(notification.presetSlot)
        notification.accept(PresetNotificationApplier(preset))
    }


    func visit(_ notification: DeviceSettingsNotification) {
        device.defaultPresetSlot = notification.defaultPresetSlot
        device.standbyLightingEnabled = notification.standbyLightingEnabled
        device.outletsSwitched = notification.outletsSwitched
        for outlet in device.outlets {
            outlet.isEnabledForWirelessRemoteButton = notification.wirelessRemoteButtonOutletSlotsEnabled.contains(where: { $0 == outlet.outletSlot })
        }
    }
    
    func visit(_ notification: DeviceStateNotification) {
        // Take our initial selected temperature from the existing targetTemperature
        if device.selectedTemperature == 0 {
            device.selectedTemperature = device.targetTemperature
        }
        device.targetTemperature = notification.targetTemperature
        device.actualTemperature = notification.actualTemperature
        device.getOutletBySlot(outletSlot: Outlet.outletSlot0)?.isRunning = notification.outletSlot0IsRunning
        device.getOutletBySlot(outletSlot: Outlet.outletSlot1)?.isRunning = notification.outletSlot1IsRunning
        device.secondsRemaining = notification.secondsRemaining
        device.updateRunningState(notification.runningState)
    }
    
    func visit(_ notification: ControlsOperatedNotification) {
        if let selectedTemperature = notification.selectedTemperature {
            device.selectedTemperature = selectedTemperature
        }
        device.targetTemperature = notification.targetTemperature
        device.actualTemperature = notification.actualTemperature
        device.getOutletBySlot(outletSlot: Outlet.outletSlot0)?.isRunning = notification.outletSlot0IsRunning
        device.getOutletBySlot(outletSlot: Outlet.outletSlot1)?.isRunning = notification.outletSlot1IsRunning
        device.secondsRemaining = notification.secondsRemaining
        device.updateRunningState(notification.runningState)
    }
    
    func visit(_ notification: DeviceNicknameNotification) {
        device.nickname = notification.nickname
    }
    
    func visit(_ notification: PairedClientSlotsNotification) {
        let existingSlots = device.pairedClients.map(\.clientSlot)
        let newSlots = notification.pairedClientSlots
        
        if (newSlots != existingSlots) {
            let addedSlots = newSlots.filter({ newSlot in !existingSlots.contains(newSlot) })
            addedSlots.forEach({
                device.addPairedClient(PairedClient(clientSlot: $0, name: ""))
            })
            
            let removedSlots = existingSlots.filter({ existingSlot in !newSlots.contains(existingSlot) })
            removedSlots.forEach({
                if let removed = device.removePairedClientBySlot($0) {
                    // Always delete from the modelContext in addition to modifying the model
                    modelContext.delete(removed)
                }
            })
        }
    }
    
    func visit(_ notification: PairedClientDetailsNotification) {
        if let name = notification.name {
            if let client = device.getPairedClientBySlot(notification.pairedClientSlot) {
                notification.accept(PairedClientNotificationApplier(client))
            } else {
                device.addPairedClient(PairedClient(clientSlot: notification.pairedClientSlot, name: name))
            }
        } else {
            // Shouldn't really happen now that we're only requesting details for clientSlots
            // that are supposed to be populated
            if let removed = device.removePairedClientBySlot(notification.pairedClientSlot) {
                modelContext.delete(removed)
            }
        }
    }
    
    func visit(_ notification: OutletSettingsNotification) {
        if let outlet = device.getOutletBySlot(outletSlot: notification.outletSlot) {
            notification.accept(OutletNotificationApplier(outlet))
        }
    }
    
    func visit(_ notification: TechnicalInformationNotification) {
        device.technicalInformation = TechnicalInformation(
            valveType: notification.valveType,
            valveSoftwareVersion: notification.valveSoftwareVersion,
            uiType: notification.uiType,
            uiSoftwareVersion: notification.uiSoftwareVersion,
            bluetoothSoftwareVersion: notification.bluetoothSoftwareVersion
        )
    }
    
    func visit(_ notification: UnknownNotification) {
        // TODO: Persist technical information in the model.
    }
}

extension Device: ObservableModel {
    func observationRegistrar() -> ObservationRegistrar {
        return _$observationRegistrar
    }
}
