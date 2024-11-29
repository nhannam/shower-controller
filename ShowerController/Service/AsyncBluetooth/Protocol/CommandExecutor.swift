//
//  CommandExecutor.swift
//  ShowerController
//
//  Created by Nigel Hannam on 27/10/2024.
//

import Foundation
import AsyncBluetooth
@preconcurrency import Combine

actor CommandExecutor {
    private static let logger = LoggerFactory.logger(CommandExecutor.self)

    let peripheral: Peripheral
    
    init(peripheral: Peripheral) {
        self.peripheral = peripheral
    }
}

extension CommandExecutor: DeviceCommandVisitor {
    typealias Response = DeviceNotification
    
    private func writeData(payloadWithCrc: Data) async throws {
        var startIndex = 0
        
        let totalBytes = payloadWithCrc.count
        while (startIndex < totalBytes) {
            let chunk = payloadWithCrc.subdata(in: startIndex..<(min(startIndex + ProtocolConstants.writeChunkLength, totalBytes)))
            try await peripheral.writeValue(
                chunk,
                forCharacteristicWithCBUUID: Characteristic.CHARACTERISTIC_WRITE,
                ofServiceWithCBUUID: Service.SERVICE_MIRA,
                type: .withResponse
            )
            startIndex += ProtocolConstants.writeChunkLength
        }
        Self.logger.debug("Written: \(payloadWithCrc.hexDescription)")
    }

    private func writeData(_ payload: Data, command: DeviceCommand, clientSlot: UInt8, clientSecret: Data) async throws -> DeviceNotification {
        let dataAccumulator = DataAccumulator(clientSlot: clientSlot)
        let notificationParser = NotificationParser(peripheral: peripheral, command: command)

        var notificationData = await peripheral.characteristicValueUpdatedPublisher
            .filter { $0.characteristic.uuid == Characteristic.CHARACTERISTIC_NOTIFICATIONS }
            .compactMap(\.value)
            .compactMap({ dataAccumulator.accumulate($0) })
            .compactMap({ notificationParser.parseNotification($0) })
            .buffer(size: 1, prefetch: .keepFull, whenFull: .dropNewest)
            .values
            .makeAsyncIterator()
        
        let payloadWithCrc = payload.withCrc(clientSecret: clientSecret)
        try await writeData(payloadWithCrc: payloadWithCrc)
        
        if let notification = await notificationData.next() {
            return notification
        } else {
            throw BluetoothServiceError.notificationNotReceived
        }
    }
    
    private func writeData<Command: PairedDeviceCommand>(_ payload: Data, command: Command) async throws -> DeviceNotification {
        return try await writeData(payload, command: command, clientSlot: command.clientSlot, clientSecret: command.clientSecret)
    }

    func visit(_ command: PairDevice) async throws -> DeviceNotification {
        let name = command.clientName.data(using: .utf8)!.withPaddingTo(length: 20)
        let payload = Data(command.clientSecret + name)
        
        let pairingClientSlot = AsyncBluetoothService.pairingClientSlot
        let data = Data([pairingClientSlot, 0xeb, UInt8(payload.count)] + payload)
        
        return try await writeData(
            data,
            command: command,
            clientSlot: pairingClientSlot,
            clientSecret: PairingSecret.pairingClientSecret
        )
    }
    
    func visit(_ command: UnpairDevice) async throws -> DeviceNotification {
        return try await writeData(
            Data([command.clientSlot, 0xeb, 0x01, command.pairedClientSlot]),
            command: command
        )
    }
    
    func visit(_ command: RequestPairedClientSlots) async throws -> DeviceNotification {
        return try await writeData(
            Data([command.clientSlot, 0x6b, 0x01, 0x00]),
            command: command
        )
    }
    
    func visit(_ command: RequestPairedClientDetails) async throws -> DeviceNotification {
        return try await writeData(
            Data([command.clientSlot, 0x6b, 0x01, 0x10 + command.pairedClientSlot]),
            command: command
        )
    }
    
    func visit(_ command: RequestDeviceInformation) async throws -> DeviceNotification {
        let manufacturerName: String = try await peripheral.readValue(
            forCharacteristicWithCBUUID: Characteristic.CHARACTERISTIC_MANUFACTURER_NAME,
            ofServiceWithCBUUID: Service.SERVICE_DEVICE_INFORMATION
        ) ?? ""
        let modelNumber: String = try await peripheral.readValue(
            forCharacteristicWithCBUUID: Characteristic.CHARACTERISTIC_MODEL_NUMBER,
            ofServiceWithCBUUID: Service.SERVICE_DEVICE_INFORMATION
        ) ?? ""
        let hardwareRevision: Data? = try await peripheral.readValue(
            forCharacteristicWithCBUUID: Characteristic.CHARACTERISTIC_HARDWARE_REVISION,
            ofServiceWithCBUUID: Service.SERVICE_DEVICE_INFORMATION
        )
        let firmwareRevision: Data? = try await peripheral.readValue<Data>(
            forCharacteristicWithCBUUID: Characteristic.CHARACTERISTIC_FIRMWARE_REVISION,
            ofServiceWithCBUUID: Service.SERVICE_DEVICE_INFORMATION
        )
        let serialNumber: Data? = try await peripheral.readValue(
            forCharacteristicWithCBUUID: Characteristic.CHARACTERISTIC_SERIAL_NUMBER,
            ofServiceWithCBUUID: Service.SERVICE_DEVICE_INFORMATION
        )
        
        return DeviceInformationNotification(
            deviceId: command.deviceId,
            manufacturerName: manufacturerName,
            modelNumber: modelNumber,
            hardwareRevision: hardwareRevision?.hexDescription ?? "",
            firmwareRevision: firmwareRevision?.hexDescription ?? "",
            serialNumber: serialNumber?.hexDescription ?? ""
        )
    }
    
    func visit(_ command: RequestNickname) async throws -> DeviceNotification {
        return try await writeData(
            Data([command.clientSlot, 0x44, 0x00]),
            command: command
        )
    }
    
    func visit(_ command: UpdateNickname) async throws -> DeviceNotification {
        let payload = command.nickname.data(using: .utf8)!.withPaddingTo(length: 16)
        return try await writeData(
            Data([command.clientSlot, 0xc4, UInt8(payload.count)]) + payload,
            command: command
        )
    }
    
    func visit(_ command: RequestState) async throws -> DeviceNotification {
        return try await writeData(
            Data([command.clientSlot, 0x07, 0x00]),
            command: command
        )
    }
    
    func visit(_ command: RequestDeviceSettings) async throws -> DeviceNotification {
        return try await writeData(
            Data([command.clientSlot, 0x3e, 0x00]),
            command: command
        )
    }
    
    func visit(_ command: UpdateDefaultPresetSlot) async throws -> DeviceNotification {
        return try await writeData(
            Data([command.clientSlot, 0xbe, 0x02, 0x02, command.presetSlot]),
            command: command
        )
    }
    
    func visit(_ command: UpdateWirelessRemoteButtonSettings) async throws -> DeviceNotification {
        let outlet0: UInt8 = command.outletSlotsEnabled.contains(Outlet.outletSlot0) ? ProtocolConstants.outlet0EnabledBitMask : 0x00
        let outlet1: UInt8 = command.outletSlotsEnabled.contains(Outlet.outletSlot1) ? ProtocolConstants.outlet1EnabledBitMask : 0x00
        return try await writeData(
            Data([command.clientSlot, 0xbe, 0x02, 0x01, outlet0 | outlet1 ]),
            command: command
        )
    }
    
    func visit(_ command: UpdateControllerSettings) async throws -> DeviceNotification {
        let lightingDisabled: UInt8 = command.standbyLightingEnabled ? 0x00 : ProtocolConstants.standbyLightingDisabledBitMask
        let topButtonOutletType: UInt8 = command.outletsSwitched ? ProtocolConstants.outletsSwitchedBitMask : 0x00
        return try await writeData(
            Data([command.clientSlot, 0xbe, 0x02, 0x03, lightingDisabled | topButtonOutletType]),
            command: command
        )
    }

    func visit(_ command: RequestPresetSlots) async throws -> DeviceNotification {
        return try await writeData(
            Data([command.clientSlot, 0x30, 0x01, 0x80]),
            command: command
        )
    }
    
    func visit(_ command: RequestPresetDetails) async throws -> DeviceNotification {
        return try await writeData(
            Data([command.clientSlot, 0x30, 0x01, 0x40 + command.presetSlot]),
            command: command
        )
    }
    
    func visit(_ command: UpdatePresetDetails) async throws -> DeviceNotification {
        // 00 b0 18
        // 00 01 c2 64 84 02 00 00
        // NAME: 57 61 72 6d 20 42 61 74 68 00 00 00 00 00 00 00
        let outletByte = command.outletSlot == Outlet.outletSlot0 ? ProtocolConstants.outlet0EnabledBitMask : ProtocolConstants.outlet1EnabledBitMask
        let payload = Data(
            [command.clientSlot, 0xb0, 0x18, command.presetSlot] +
            Converter.celciusToData(command.targetTemperature) +
            [ProtocolConstants.flowRateMaximum, Converter.secondsToData(command.durationSeconds), outletByte, 0x00, 0x00]
        ) + command.name.data(using: .utf8)!.withPaddingTo(length: 16)
        
        return try await writeData(
            payload,
            command: command
        )
    }
    
    func visit(_ command: DeletePresetDetails) async throws -> DeviceNotification {
        let payload = Data([command.clientSlot, 0xb0, 0x18, command.presetSlot, 0x01 ]) + Data(count: 22)
        return try await writeData(
            payload,
            command: command
        )
    }
    
    func visit(_ command: StartPreset) async throws -> DeviceNotification {
        return try await writeData(
            Data([command.clientSlot, 0xb1, 0x01, command.presetSlot]),
            command: command
        )
    }
    
    func visit(_ command: OperateOutletControls) async throws -> DeviceNotification {
        return try await writeData(
            Data(
                [command.clientSlot, 0x87, 0x05, Converter.runningStateToData(command.runningState)] +
                Converter.celciusToData(command.targetTemperature) +
                [
                    command.outletSlot0Running ? ProtocolConstants.flowRateMaximum : 0x00,
                    command.outletSlot1Running ? ProtocolConstants.flowRateMaximum : 0x00
                ]
            ),
            command: command
        )
    }
    
    func visit(_ command: RequestOutletSettings) async throws -> DeviceNotification {
        let commandType: UInt8 = command.outletSlot == Outlet.outletSlot0 ? 0x0f : 0x10
        return try await writeData(
            Data([ command.clientSlot, commandType, 0x00 ]),
            command: command
        )
    }
    
    
    func visit(_ command: UpdateOutletSettings) async throws -> DeviceNotification {
        let commandType: UInt8 = command.outletSlot == Outlet.outletSlot0 ? 0x8f : 0x90
        let outletFlag: UInt8 = command.outletSlot == Outlet.outletSlot0 ? 0x00 : 0x04
        
        return try await writeData(
            Data(
                [command.clientSlot, commandType, 0x0b] +
                [outletFlag, outletFlag, 0x08, ProtocolConstants.flowRateMaximum, Converter.secondsToData(command.maximumDurationSeconds)] +
                Converter.celciusToData(command.maximumTemperature) +
                Converter.celciusToData(command.minimumTemperature) +
                /*
                 Unclear what this value is intended to be - looks like another temperature.
                 When min and max temps are both set to 30c, this is also set to 30c
                 If you try to set outside the min/max range it appears to cause the command to be rejected
                 Defaults to 0x7c (38c), but is changed when that is outside permitted range
                 - maybe it's an attempt to prevent accidental setting of a high minimum temperature?
                 */
                Converter.celciusToData(command.thresholdTemperature)
            ),
            command: command
        )
    }
    
    func visit(_ command: RestartDevice) async throws -> DeviceNotification {
        return try await writeData(
            Data([ command.clientSlot, 0xf4, 0x01, 0x01 ]),
            command: command
        )
    }
    
    func visit(_ command: FactoryResetDevice) async throws -> DeviceNotification {
        return try await writeData(
            Data([ command.clientSlot, 0xf4, 0x01, 0x02 ]),
            command: command
        )
    }
    
    func visit(_ command: RequestTechnicalInformation) async throws -> DeviceNotification {
        return try await writeData(
            Data([ command.clientSlot, 0x32, 0x01, 0x01 ]),
            command: command
        )
    }
    
    func visit(_ command: UnknownRequestTechnicalInformation) async throws -> DeviceNotification {
        return try await writeData(
            Data([ command.clientSlot, 0x41, 0x00 ]),
            command: command
        )
    }
    
    func visit(_ command: UnknownCommand) async throws -> DeviceNotification {
//        return try await writeData(Data([ command.clientSlot, 0x40, 0x00 ]), command: command)
//        return try await writeData(Data([ command.clientSlot, 0x40, 0x01, 0x01 ]), command: command)
        throw DeviceServiceError.internalError
    }
}
