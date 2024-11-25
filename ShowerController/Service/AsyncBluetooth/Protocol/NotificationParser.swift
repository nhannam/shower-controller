//
//  NotificationHandler.swift
//  ShowerController
//
//  Created by Nigel Hannam on 26/10/2024.
//

import Foundation

final class NotificationParser: Sendable {
    private static let logger = LoggerFactory.logger(NotificationParser.self)
    
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
    
    func parseNotification(_ data: Data, command: DeviceCommand) -> DeviceNotification? {
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
                    notification = PairSuccessNotification(deviceId: command.deviceId, clientSlot: successId)
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
                notificationType = "UnknownSlotsOperation"
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
                notificationType = "Unknown4ByteNotification"
                notification = nil
            }
            
        case 10:
            // payload example [00 01 e0 00 c0 00 00 07 08 09]
            notificationType = "DeviceState"
            notification = DeviceStateNotification(
                deviceId: command.deviceId,
                clientSlot: clientSlot,
                // payload[1] always 01 (not ALWAYS - sometime 00, sometimes 04)
                targetTemperature: Converter.celciusFromData(payload[2]),
                // payload[3] always 01 (sometimes 00 - maybe matching the controlsoperated values?)
                actualTemperature: Converter.celciusFromData(payload[4]),
                outletSlot0IsRunning: payload[5] == 0x64,
                outletSlot1IsRunning: payload[6] == 0x64,
                secondsRemaining: Converter.secondsFromData(payload.subdata(in: 7..<9)),
                runningState: Converter.runningStateFromData(payload[0])
                // payload[9] this seems to be a counter of sucessfull operations that loops from 0x09 through 0x0f
            )

        case 11:
            // controls operated response
            let changeType = payload[0] // indicates type of controls
            switch changeType {
            case 0x01, 0x80:
                // looks like 0x01 indicates a sucessfull change, 0x80 indicates no resulting change
                notificationType = "ControlsOperated"
                notification = ControlsOperatedNotification(
                    deviceId: command.deviceId,
                    clientSlot: clientSlot,
                    selectedTemperature: (command as? OperateOutletControls)?.targetTemperature,
                    // payload[2] always 01
                    targetTemperature: Converter.celciusFromData(payload[3]),
                    // payload[4] always 01  (sometime preset started=00, other 0x01 maybe reflecting what is sent in operate controls command)
                    actualTemperature: Converter.celciusFromData(payload[5]),
                    outletSlot0IsRunning: payload[6] == 0x64,
                    outletSlot1IsRunning: payload[7] == 0x64,
                    secondsRemaining: Converter.secondsFromData(payload.subdata(in: 8..<10)),
                    runningState: Converter.runningStateFromData(payload[1])
                    // payload[10] this seems to be a counter of sucessfull operations that loops from 0x09 through 0x0f
                )
            case 0x00, 0x04, 0x08:
                if let outletSettingsCommand = command as? RequestOutletSettings {
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
                        minimumTemperature: Converter.celciusFromData(payload[8]),
                        maximumTemperature: Converter.celciusFromData(payload[6]),
                        maximumDurationSeconds: Converter.secondsFromData(payload[4])
                    )
                } else {
                    notificationType = "Unknown11BytePayload"
                    notification = nil
                }
            default:
                Self.logger.warning("Unexpected changeType received in message")
                notificationType = "UnknownControlsOperation"
                notification = nil
            }
                        
        case 16:
            // Nickname response
            switch command {
            case is RequestNickname:
                notificationType = "Nickname"
                notification = DeviceNicknameNotification(
                    deviceId: command.deviceId,
                    clientSlot: clientSlot,
                    nickname: String(data: payload.prefix(while: { $0 != 0x00 }), encoding: .utf8) ?? ""
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
                notificationType = "Unknown16BytePayload"
                notification = nil
            }
            
        case 18:
            // Written: 02 40 01 01 a4 dd
            // Notification data received: 42 01 12 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
            notificationType = "Unknown18BytePayload"
            notification = UnknownNotification(deviceId: command.deviceId)

        case 20:
            // Value: 40 01 14 69 50 68 6f 6e 65 00 00 00 00 00 00 00 00 00 00 00 00 00 00
            notificationType = "ClientDetails"
            if let requestClientCommand = command as? RequestPairedClientDetails {
                let nameReceived = String(data: payload.prefix(while: { $0 != 0x00 }), encoding: .utf8) ?? ""
                // Sometimes, a lack of client is indicated by all 0x00 name
                notification = PairedClientDetailsNotification(
                    deviceId: command.deviceId,
                    clientSlot: clientSlot,
                    pairedClientSlot: requestClientCommand.clientSlot,
                    name: nameReceived.isEmpty ? nil : nameReceived
                )
            }else {
                notification = nil
            }
            
        case 24:
            // preset details response
            // Value: 40018a0001a900e5000007080a
            notificationType = "PresetDetails"
            notification = PresetDetailsNotification(
                deviceId: command.deviceId,
                clientSlot: clientSlot,
                presetSlot: payload[0],
                // The bytes in this payload match the ones in the UpdatePresetDetails command
                // payload[1] always 01
                // payload[3] - seems to always be 0x64
                // payload[6] - 00
                // payload[7] - 00
                name: String(data: payload.dropFirst(8).prefix(while: { $0 != 0x00 }), encoding: .utf8) ?? "",
                outletSlot: (payload[5] & BitMasks.outlet0Enabled) == BitMasks.outlet0Enabled ? Outlet.outletSlot0 : Outlet.outletSlot1,
                targetTemperature: Converter.celciusFromData(payload[2]),
                durationSeconds: Converter.secondsFromData(payload[4])
            )



        default:
            notificationType = "UNKNOWN"
            notification = nil
        }

        Self.logger.debug("Response -- Type: \(notificationType), Payload: \(String(describing: payload.hexDescription))")
        return notification
    }
}
