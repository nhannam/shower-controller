//
//  IsExpectedNotificationTypeVisitor.swift
//  ShowerController
//
//  Created by Nigel Hannam on 07/11/2024.
//

import Foundation

class IsExpectedNotificationTypeVisitor: DeviceCommandVisitor {
    let notification: DeviceNotification
    
    init(_ notification: DeviceNotification) {
        self.notification = notification
    }

    func visit(_ command: PairDevice) async throws -> Bool {
        return notification is PairSuccessNotification || notification is FailedNotification
    }
    
    func visit(_ command: UnpairDevice) async throws -> Bool {
        return notification is UnpairSuccessNotification || notification is FailedNotification
    }

    func visit(_ command: RequestNickname) async throws -> Bool {
        return notification is DeviceNicknameNotification
    }
    
    func visit(_ command: UpdateNickname) async throws -> Bool {
        return notification is DeviceOperationStatus
    }
    
    func visit(_ command: RequestState) async throws -> Bool {
        return notification is DeviceStateNotification
    }
    
    func visit(_ command: RequestDeviceSettings) async throws -> Bool {
        return notification is DeviceSettingsNotification
    }
    
    func visit(_ command: UpdateDefaultPresetSlot) async throws -> Bool {
        return notification is DeviceOperationStatus
    }
    
    func visit(_ command: RequestPresetSlots) async throws -> Bool {
        return notification is PresetSlotsNotification
    }
    
    func visit(_ command: RequestPresetDetails) async throws -> Bool {
        return notification is PresetDetailsNotification
    }
    
    func visit(_ command: UpdatePresetDetails) async throws -> Bool {
        return notification is DeviceOperationStatus
    }
    
    func visit(_ command: DeletePresetDetails) async throws -> Bool {
        return notification is DeviceOperationStatus
    }
    
    func visit(_ command: StartPreset) async throws -> Bool {
        return notification is ControlsOperatedNotification
    }
    
    func visit(_ command: OperateOutletControls) async throws -> Bool {
        return notification is ControlsOperatedNotification
    }
    
    func visit(_ command: RequestPairedClientSlots) async throws -> Bool {
        return notification is PairedClientSlotsNotification
    }
    
    func visit(_ command: RequestPairedClientDetails) async throws -> Bool {
        return notification is PairedClientDetailsNotification
    }
    
    func visit(_ command: RequestOutletSettings) async throws -> Bool {
        return notification is OutletSettingsNotification
    }
    
    func visit(_ command: UpdateOutletSettings) async throws -> Bool {
        return notification is DeviceOperationStatus
    }
    
    func visit(_ command: UpdateControllerSettings) async throws -> Bool {
        return notification is DeviceOperationStatus
    }
    
    func visit(_ command: UpdateWirelessRemoteButtonSettings) async throws -> Bool {
        return notification is DeviceOperationStatus
    }
    
    func visit(_ command: RestartDevice) async throws -> Bool {
        return notification is DeviceOperationStatus
    }
    
    func visit(_ command: FactoryResetDevice) async throws -> Bool {
        return notification is DeviceOperationStatus
    }
    
    func visit(_ command: RequestTechnicalInformation) async throws -> Bool {
        return notification is TechnicalInformationNotification
    }
    
    func visit(_ command: UnknownRequestTechnicalInformation) async throws -> Bool {
        return notification is UnknownNotification
    }
    
    func visit(_ command: UnknownCommand) async throws -> Bool {
        return notification is UnknownNotification
    }
}
