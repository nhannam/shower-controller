//
//  CommandDispatcher.swift
//  ShowerController
//
//  Created by Nigel Hannam on 27/10/2024.
//

import Foundation
import AsyncBluetooth

actor CommandDispatcher {
    private static let logger = LoggerFactory.logger(CommandDispatcher.self)

    let peripheral: Peripheral
    let clientSlot: UInt8
    let clientSecret: Data
    
    init(peripheral: Peripheral, dataClientSlot: UInt8, clientSecret: Data) {
        self.peripheral = peripheral
        self.clientSlot = dataClientSlot
        self.clientSecret = clientSecret
    }
}

extension CommandDispatcher: DeviceCommandVisitor {
    typealias Response = Void
    
    private func writeData(payloadWithCrc: Data) async throws {
        var startIndex = 0
        while (startIndex < payloadWithCrc.count) {
            let chunk = payloadWithCrc.subdata(in: startIndex..<(min(startIndex+20, payloadWithCrc.count)))
            try await peripheral.writeValue(
                chunk,
                forCharacteristicWithCBUUID: Characteristic.CHARACTERISTIC_WRITE,
                ofServiceWithCBUUID: Service.SERVICE_MIRA,
                type: .withResponse
            )
            startIndex += 20
        }
        Self.logger.debug("Written: \(payloadWithCrc.hexDescription)")
    }
    
    private func writeData(_ payload: Data, clientSecret: Data) async throws {
        let withCrc = payload.withCrc(clientSecret: clientSecret)
        try await writeData(payloadWithCrc: withCrc)
    }
    
    func visit(_ command: PairDevice) async throws {
        let name = command.clientName.data(using: .utf8)!.withPaddingTo(length: 20)
        let payload = Data(clientSecret + name)
        
        let data = Data([0x00, 0xeb, UInt8(payload.count)] + payload)
        
        try await writeData(
            data,
            clientSecret: PairingSecret.pairingClientSecret
        )
    }
    
    func visit(_ command: UnpairDevice) async throws {
        try await writeData(Data([clientSlot, 0xeb, 0x01, command.clientSlot]), clientSecret: clientSecret)
    }
    
    func visit(_ command: RequestPairedClientSlots) async throws {
        try await writeData(Data([clientSlot, 0x6b, 0x01, 0x00]), clientSecret: clientSecret)
    }
    
    func visit(_ command: RequestPairedClientDetails) async throws {
        try await writeData(Data([clientSlot, 0x6b, 0x01, 0x10 + command.clientSlot]), clientSecret: clientSecret)
    }
    
    func visit(_ command: RequestNickname) async throws {
        try await writeData(Data([clientSlot, 0x44, 0x00]), clientSecret: clientSecret)
    }
    
    func visit(_ command: UpdateNickname) async throws {
        let payload = command.nickname.data(using: .utf8)!.withPaddingTo(length: 16)
        try await writeData(Data([clientSlot, 0xc4, UInt8(payload.count)]) + payload, clientSecret: clientSecret)
    }
    
    func visit(_ command: RequestState) async throws {
        try await writeData(Data([clientSlot, 0x07, 0x00]), clientSecret: clientSecret)
    }
    
    func visit(_ command: RequestDeviceSettings) async throws {
        try await writeData(Data([clientSlot, 0x3e, 0x00]), clientSecret: clientSecret)
    }
    
    func visit(_ command: UpdateDefaultPresetSlot) async throws {
        try await writeData(Data([clientSlot, 0xbe, 0x02, 0x02, command.presetSlot]), clientSecret: clientSecret)
    }
    
    func visit(_ command: UpdateWirelessRemoteButtonSettings) async throws -> Void {
        let outlet0: UInt8 = command.outletSlotsEnabled.contains(Device.outletSlot0) ? BitMasks.outlet0Enabled : 0x00
        let outlet1: UInt8 = command.outletSlotsEnabled.contains(Device.outletSlot1) ? BitMasks.outlet1Enabled : 0x00
        try await writeData(Data([clientSlot, 0xbe, 0x02, 0x01, outlet0 | outlet1 ]), clientSecret: clientSecret)
    }
    
    func visit(_ command: UpdateControllerSettings) async throws -> Void {
        let lightingDisabled: UInt8 = command.standbyLightingEnabled ? 0x00 : BitMasks.standbyLightingDisabled
        let topButtonOutletType: UInt8 = command.outletsSwitched ? BitMasks.outletsSwitched : 0x00
        try await writeData(Data([clientSlot, 0xbe, 0x02, 0x03, lightingDisabled | topButtonOutletType]), clientSecret: clientSecret)
    }

    func visit(_ command: RequestPresetSlots) async throws {
        try await writeData(Data([clientSlot, 0x30, 0x01, 0x80]), clientSecret: clientSecret)
    }
    
    func visit(_ command: RequestPresetDetails) async throws {
        try await writeData(Data([clientSlot, 0x30, 0x01, 0x40 + command.presetSlot]), clientSecret: clientSecret)
    }
    
    func visit(_ command: UpdatePresetDetails) async throws {
        // 00 b0 18
        // 00 01 c2 64 84 02 00 00
        // NAME: 57 61 72 6d 20 42 61 74 68 00 00 00 00 00 00 00
        let outletByte = command.outletSlot == Device.outletSlot0 ? BitMasks.outlet0Enabled : BitMasks.outlet1Enabled
        let payload = Data([
            clientSlot, 0xb0, 0x18,
            command.presetSlot, 0x01,
            Converter.celciusToData(command.targetTemperature), 0x64,
            Converter.secondsToData(command.durationSeconds),
            outletByte, 0x00, 0x00
        ]) + command.name.data(using: .utf8)!.withPaddingTo(length: 16)
        
        try await writeData(payload, clientSecret: clientSecret)
    }
    
    func visit(_ command: DeletePresetDetails) async throws {
        let payload = Data([clientSlot, 0xb0, 0x18, command.presetSlot, 0x01 ]) + Data(count: 22)
        try await writeData(payload, clientSecret: clientSecret)
    }
    
    func visit(_ command: StartPreset) async throws {
        try await writeData(
            Data([clientSlot, 0xb1, 0x01, command.presetSlot]),
            clientSecret: clientSecret
        )
    }
    
    func visit(_ command: OperateOutletControls) async throws {
        try await writeData(
            Data([
                clientSlot,
                0x87,
                0x05,
                Converter.timerStateToData(command.timerState),
                0x01,
                Converter.celciusToData(command.targetTemperature),
                command.outletSlot0Running ? 0x64 : 0x00,
                command.outletSlot1Running ? 0x64 : 0x00
            ]),
            clientSecret: clientSecret
        )
    }
    
    func visit(_ command: RequestOutletSettings) async throws {
        let commandType: UInt8 = command.outletSlot == Device.outletSlot0 ? 0x0f : 0x10
        try await writeData(Data([ clientSlot, commandType, 0x00 ]), clientSecret: clientSecret)
    }
    
    
    func visit(_ command: UpdateOutletSettings) async throws {
        let commandType: UInt8 = command.outletSlot == Device.outletSlot0 ? 0x8f : 0x90
        let outletFlag: UInt8 = command.outletSlot == Device.outletSlot0 ? 0x00 : 0x04
        
        try await writeData(
            Data([
                clientSlot,
                commandType,
                0x0b,
                
                outletFlag,
                outletFlag,
                0x08,
                0x64,
                Converter.secondsToData(command.maximumDurationSeconds),
                0x01,
                Converter.celciusToData(command.maximumTemperature),
                0x01,
                Converter.celciusToData(command.minimumTemperature),
                0x01,
                0x7c
            ]),
            clientSecret: clientSecret
        )
    }
    
    func visit(_ command: RestartDevice) async throws -> Void {
        try await writeData(Data([ clientSlot, 0xf4, 0x01, 0x01 ]), clientSecret: clientSecret)
    }
    
    func visit(_ command: FactoryResetDevice) async throws -> Void {
        try await writeData(Data([ clientSlot, 0xf4, 0x01, 0x02 ]), clientSecret: clientSecret)
    }
    
    func visit(_ command: RequestTechnicalInformation) async throws -> Void {
        try await writeData(Data([ clientSlot, 0x32, 0x01, 0x01 ]), clientSecret: clientSecret)
    }
    
    func visit(_ command: UnknownRequestTechnicalInformation) async throws -> Void {
        try await writeData(Data([ clientSlot, 0x41, 0x00 ]), clientSecret: clientSecret)
    }
    
    func visit(_ command: UnknownCommand) async throws -> Void {
//        try await writeData(Data([ clientSlot, 0x40, 0x00 ]), clientSecret: clientSecret)
//        try await writeData(Data([ clientSlot, 0x40, 0x01, 0x01 ]), clientSecret: clientSecret)
    }
}
