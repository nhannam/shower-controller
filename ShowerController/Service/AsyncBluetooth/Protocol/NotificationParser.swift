//
//  NotificationHandler.swift
//  ShowerController
//
//  Created by Nigel Hannam on 26/10/2024.
//

import Foundation
import AsyncBluetooth

final class NotificationParser: Sendable {
    private static let logger = LoggerFactory.logger(NotificationParser.self)
    
    private let peripheral: Peripheral
    private let command: DeviceCommand
    
    init(peripheral: Peripheral, command: DeviceCommand) {
        self.peripheral = peripheral
        self.command = command
    }
    
    private func bitsSet(data: Data) -> [UInt8] {
        var bitsSet: [UInt8] = []
        
        var slotNumber: UInt8 = 0
        for byte in data.reversed() {
            for bit in (0..<8) {
                if ((byte & (1 << bit)) != 0) {
                    bitsSet.append(slotNumber)
                }
                slotNumber += 1
            }
        }

        return bitsSet
    }
    
    func parseNotification(_ data: Data) -> DeviceNotification? {
        // [ 40+deviceSlot, notificationType, dataLength, ...data ]
        // data can continue in subsequent notifications - use length to determine end
        let clientSlot = data[0] - 0x40
        // What's data[1]?  Looks to be 0x01 - maybe a success indicator?
        let payloadLength = data[2]
        let payload = Data(data.dropFirst(3))
        let notificationType: String
        let notification: DeviceNotification?
        
        switch payloadLength {
        case 1:
            // This seems to suggest that the last bit doesn't always represnt the client slot, or that this response length always indicates a pairing response.
            let successId = payload[0]
            if successId < 0x80 {
                switch command {
                case is PairDevice:
                    // On pairing response, successId contains new client slot
                    // success: 40 01 01 [00] - data[3] = paired client slot/index
                    notificationType = "PairSuceeded"
                    notification = PairSuccessNotification(
                        deviceId: command.deviceId,
                        clientSlot: successId,
                        name: peripheral.name ?? "Unnamed Device"
                    )
                case let unpairCommand as UnpairDevice:
                    // On pairing response, successId contains new client slot
                    // success: 40 01 01 [00] - data[3] = paired client slot/index
                    notificationType = "UnpairSuceeded"
                    notification = UnpairSuccessNotification(
                        deviceId: command.deviceId,
                        clientSlot: unpairCommand.clientSlot
                    )
                default:
                    // On nickname update etc, client slot if valid, successId = 0x01
                    // 40 01 01 01.
                    notificationType = "RequestSuceeded"
                    notification = SuccessNotification(deviceId: command.deviceId)
                }
            } else {
                // fail: 40 01 01 [80] - although this indicates a failure
                notificationType = "RequestFailed"
                notification = FailedNotification(deviceId: command.deviceId)
            }

        case 2:
            // preset slots response
            // payload example [ 00 01 ]
            // the last byte (or possily both) each bit thats set represents a preset that exists
            switch command {
            case is RequestPresetSlots:
                notificationType = "PresetSlots"
                notification = PresetSlotsNotification(
                    deviceId: command.deviceId,
                    clientSlot: clientSlot,
                    presetSlots: bitsSet(data: payload)
                )
            case is RequestPairedClientSlots:
                notificationType = "ClientSlots"
                notification = PairedClientSlotsNotification(
                    deviceId: command.deviceId,
                    clientSlot: clientSlot,
                    pairedClientSlots: bitsSet(data: payload)
                )
            default:
                notificationType = "UnexpectedSlotsOperation"
                notification = nil
            }

        case 4:
            switch command {
            case is RequestDeviceSettings:
                notificationType = "DeviceSettings"

                var wirelessRemoteButtonOutletSlotsEnabled: [Int] = []
                if (payload[1] & BitMasks.outlet0Enabled == BitMasks.outlet0Enabled) {
                    wirelessRemoteButtonOutletSlotsEnabled.append(Outlet.outletSlot0)
                }
                if (payload[1] & BitMasks.outlet1Enabled == BitMasks.outlet1Enabled) {
                    wirelessRemoteButtonOutletSlotsEnabled.append(Outlet.outletSlot0)
                }

                let standbyLightingEnabled = (payload[3] & BitMasks.standbyLightingDisabled) != BitMasks.standbyLightingDisabled
                let outletsSwitched = (payload[3] & BitMasks.outletsSwitched) == BitMasks.outletsSwitched
                notification = DeviceSettingsNotification(
                    deviceId: command.deviceId,
                    clientSlot: clientSlot,
                    defaultPresetSlot: payload[2],
                    standbyLightingEnabled: standbyLightingEnabled,
                    outletsSwitched: outletsSwitched,
                    wirelessRemoteButtonOutletSlotsEnabled: wirelessRemoteButtonOutletSlotsEnabled
                )
            case is UnknownRequestTechnicalInformation:
                // on technical info screen...
                // command: <client slot> 41 00 96 c5
                // notifcation: <client slot> 01 04 16 11 14 fe
                notificationType = "UnknownTechnicalInformationNotification"
                notification = UnknownNotification(deviceId: command.deviceId)

            default:
                notificationType = "Unexpected4ByteNotification"
                notification = nil
            }
            
        case 10:
            switch command {
            case is RequestState:
                // payload example [00 01 e0 00 c0 00 00 07 08 09]
                notificationType = "DeviceState"
                notification = DeviceStateNotification(
                    deviceId: command.deviceId,
                    clientSlot: clientSlot,
                    targetTemperature: Converter.celciusFromData(payload.subdata(in: 1..<3)),
                    actualTemperature: Converter.celciusFromData(payload.subdata(in: 3..<5)),
                    outletSlot0IsRunning: payload[5] == BitMasks.maximumFlowRate,
                    outletSlot1IsRunning: payload[6] == BitMasks.maximumFlowRate,
                    secondsRemaining: Converter.secondsFromData(payload.subdata(in: 7..<9)),
                    runningState: Converter.runningStateFromData(payload[0])
                    // payload[9] this seems to be a counter of sucessfull operations that loops from 0x09 through 0x0f
                )
            default:
                notificationType = "Unexpected10ByteNotification"
                notification = nil
            }

        case 11:
            // let changeType = payload[0]
            switch command {
            case is OperateOutletControls, is StartPreset:
                // looks like 0x01 indicates a sucessfull change, 0x80 indicates no resulting change
                notificationType = "ControlsOperated"
                notification = ControlsOperatedNotification(
                    deviceId: command.deviceId,
                    clientSlot: clientSlot,
                    selectedTemperature: (command as? OperateOutletControls)?.targetTemperature,
                    targetTemperature: Converter.celciusFromData(payload.subdata(in: 2..<4)),
                    actualTemperature: Converter.celciusFromData(payload.subdata(in: 4..<6)),
                    outletSlot0IsRunning: payload[6] != 0x00,
                    outletSlot1IsRunning: payload[7] != 0x00,
                    secondsRemaining: Converter.secondsFromData(payload.subdata(in: 8..<10)),
                    runningState: Converter.runningStateFromData(payload[1])
                    // payload[10] this seems to be a counter of sucessfull operations that loops from 0x09 through 0x0f
                )
                
            case let outletSettingsCommand as RequestOutletSettings:
                // changeType 0x00, 0x04, 0x08:
                // outlet1 settinga
                // Value: 42010b00000864b401e0012c017c (outlet0)
                // Value: 42010b04040864b401e0012c017c (outlet1)
                // Value  42010b04010808b401c2012c017c (outlet0 after factory reset, before any settings changes)
                // Value: 42010b08010808b401c2012c017c (outlet1 after factory reset, before any settings changes)
                notificationType = "OutletSettings"
                notification = OutletSettingsNotification(
                    deviceId: command.deviceId,
                    clientSlot: clientSlot,
                    outletSlot: outletSettingsCommand.outletSlot,
                    maximumDurationSeconds: Converter.secondsFromData(payload[4]),
                    maximumTemperature: Converter.celciusFromData(payload.subdata(in: 5..<7)),
                    minimumTemperature: Converter.celciusFromData(payload.subdata(in: 7..<9)),
                    thresholdTemperature: Converter.celciusFromData(payload.subdata(in: 9..<11))
                )
                
            default:
                notificationType = "Unexpected11BytePayload"
                notification = nil
            }
                        
        case 16:
            // Nickname response
            switch command {
            case is RequestNickname:
                notificationType = "Nickname"
                let nickname = String(data: payload.prefix(while: { $0 != 0x00 }), encoding: .utf8)
                notification = DeviceNicknameNotification(
                    deviceId: command.deviceId,
                    clientSlot: clientSlot,
                    nickname: nickname?.isEmpty ?? true ? nil : nickname
                )
            case is RequestTechnicalInformation:
                notificationType = "TechnicalInformation"
                notification = TechnicalInformationNotification(
                    deviceId: command.deviceId,
                    clientSlot: clientSlot,
                    // payload[0] = 0x00
                    valveType: payload[1],
                    // payload[2] = 0x00,
                    valveSoftwareVersion: payload[3],
                    // payload[4] = 0x00
                    uiType: payload[5],
                    // payload[6] = 0x00
                    uiSoftwareVersion: payload[7],
                    // payload[8-12] = 0x00,
                    // payload[13] = 0x2d
                    // payload[14] = 0x00
                    bluetoothSoftwareVersion: payload[15]
                )
            default:
                notificationType = "Unexpected16BytePayload"
                notification = nil
            }
            
        case 18:
            // Written: 02 40 01 01 a4 dd
            // Notification data received: 42 01 12 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
            notificationType = "Unexpected18BytePayload"
            notification = UnknownNotification(deviceId: command.deviceId)

        case 20:
            switch command {
            case let requestPairedClientCommand as RequestPairedClientDetails:
                // Value: 40 01 14 69 50 68 6f 6e 65 00 00 00 00 00 00 00 00 00 00 00 00 00 00
                notificationType = "ClientDetails"
                let nameReceived = String(data: payload.prefix(while: { $0 != 0x00 }), encoding: .utf8) ?? ""
                // Sometimes, a lack of client is indicated by all 0x00 name
                notification = PairedClientDetailsNotification(
                    deviceId: command.deviceId,
                    clientSlot: clientSlot,
                    pairedClientSlot: requestPairedClientCommand.clientSlot,
                    name: nameReceived.isEmpty ? nil : nameReceived
                )
            default:
                notificationType = "Unexpected20BytePayload"
                notification = nil
            }
            
        case 24:
            switch command {
            case is RequestPresetDetails:
                // preset details response
                // Value: 40018a0001a900e5000007080a
                notificationType = "PresetDetails"
                notification = PresetDetailsNotification(
                    deviceId: command.deviceId,
                    clientSlot: clientSlot,
                    presetSlot: payload[0],
                    // The bytes in this payload match the ones in the UpdatePresetDetails command
                    // payload[3] - seems to always be 0x64.  suspect it's flow rate
                    // payload[6] - 00
                    // payload[7] - 00
                    name: String(data: payload.dropFirst(8).prefix(while: { $0 != 0x00 }), encoding: .utf8) ?? "",
                    outletSlot: (payload[5] & BitMasks.outlet0Enabled) == BitMasks.outlet0Enabled ? Outlet.outletSlot0 : Outlet.outletSlot1,
                    targetTemperature: Converter.celciusFromData(payload.subdata(in: 1..<3)),
                    durationSeconds: Converter.secondsFromData(payload[4])
                )
            default:
                notificationType = "Unexpected24BytePayload"
                notification = nil
            }

        default:
            notificationType = "UNKNOWN"
            notification = nil
        }

        Self.logger.debug("Response -- Type: \(notificationType), Payload: \(String(describing: payload.hexDescription))")
        return notification
    }
}
