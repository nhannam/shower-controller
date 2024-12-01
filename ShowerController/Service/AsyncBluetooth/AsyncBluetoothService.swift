//
//  AsyncBluetoothService.swift
//  ShowerController
//
//  Created by Nigel Hannam on 04/11/2024.
//

import Foundation
import CoreBluetooth
import SwiftData
import AsyncBluetooth

// @ModelActor creates a single arg init, which prevents us passing the BluetoothService in
actor AsyncBluetoothService: ModelActor, BluetoothService {
    private static let logger = LoggerFactory.logger(AsyncBluetoothService.self)
    private static let author = "AsyncBluetoothService"
    static let pairingClientSlot: UInt8 = 0

    private let central: CentralManager = CentralManager()
    
    // Make timout on error boundary longer than other timeouts to reduce likelhood of loosing the
    // more granular timeout information
    private static let timeoutDuration: Duration = .seconds(5)
    private static let errorBoundaryTimeoutDuration: Duration = .seconds(6)

    nonisolated let modelExecutor: any ModelExecutor
    nonisolated let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        let modelContext = ModelContext(modelContainer)
        modelContext.author = Self.author
        
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
        self.modelContainer = modelContainer
    }

    private func errorBoundary<R: Sendable>(@_inheritActorContext _ block: @escaping @Sendable () async throws -> R) async throws -> R {
        do {
            return try await block()
        } catch let error as BluetoothServiceError {
            throw error
        } catch is TimeoutError {
            throw BluetoothServiceError.timedOut
        } catch is CancellationError {
            throw BluetoothServiceError.cancelled
        } catch BluetoothError.bluetoothUnavailable(_) {
            throw BluetoothServiceError.bluetoothUnavailable
        } catch BluetoothError.connectingInProgress, BluetoothError.disconnectingInProgress,
                BluetoothError.cancelledConnectionToPeripheral {
            throw BluetoothServiceError.cannotConnectToPeripheral
        } catch BluetoothError.errorConnectingToPeripheral(_) {
            throw BluetoothServiceError.cannotConnectToPeripheral
        } catch BluetoothError.characteristicNotFound {
            throw BluetoothServiceError.cannotMakePeripheralReady
        } catch BluetoothError.operationCancelled {
            throw BluetoothServiceError.cancelled
        } catch {
            Self.logger.debug("Unexpected error: \(error)")
            throw BluetoothServiceError.internalError
        }
    }
    
    private func ensureCentralReady() async throws {
        try await withTimeout(
            Self.timeoutDuration,
            error: BluetoothServiceError.bluetoothUnavailable
        ) {
            // With SwiftBluetooth This function will hang indefintely, which prevents the
            // 'withTimeout' task group exiting. Seems better with AsyncBluetooth
            try await self.central.waitUntilReady()
        }
    }
    
    private func getPeripheral(_ deviceId: UUID) async throws -> Peripheral? {
        try await ensureCentralReady()
        return central.retrievePeripherals(withIdentifiers: [deviceId]).first
    }

    private func connect(_ peripheral: Peripheral) async throws {
        try await withTimeout(
            Self.timeoutDuration,
            error: BluetoothServiceError.cannotConnectToPeripheral
        ) {
            try await self.central.connect(peripheral)
        }
    }

    private func makeReady(_ peripheral: Peripheral) async throws {
        try await withTimeout(
            Self.timeoutDuration,
            error: BluetoothServiceError.cannotMakePeripheralReady
        ) {
            if (peripheral.discoveredServices == nil) {
                try await peripheral.discoverServices([
                    Service.SERVICE_DEVICE_INFORMATION,
                    Service.SERVICE_MIRA
                ])
                if let showerService = peripheral.showerService() {
                    try await peripheral.discoverCharacteristics(
                        [
                            Characteristic.CHARACTERISTIC_WRITE,
                            Characteristic.CHARACTERISTIC_NOTIFICATIONS
                        ],
                        for: showerService)
//
//                    for chracteristic in showerService.discoveredCharacteristics ?? [] {
//                        try await peripheral.discoverDescriptors(for: chracteristic)
//                        for descriptor in chracteristic.descriptors ?? [] {
//                            try await peripheral.readValue(for: descriptor)
//                            print("Characteristic \(chracteristic.uuid), Descriptor \(descriptor.uuid), Value \(String(describing: descriptor.value))")
//                        }
//
//                    }
                }
                if let deviceInformationService = peripheral.deviceInformationService() {
                    try await peripheral.discoverCharacteristics(
                        [
                            Characteristic.CHARACTERISTIC_MANUFACTURER_NAME,
                            Characteristic.CHARACTERISTIC_MODEL_NUMBER,
                            Characteristic.CHARACTERISTIC_HARDWARE_REVISION,
                            Characteristic.CHARACTERISTIC_FIRMWARE_REVISION,
                            Characteristic.CHARACTERISTIC_SERIAL_NUMBER
                        ],
                        for: deviceInformationService)
                }
            }
            
            try await peripheral.setNotifyValue(
                true,
                forCharacteristicWithCBUUID: Characteristic.CHARACTERISTIC_NOTIFICATIONS,
                ofServiceWithCBUUID: Service.SERVICE_MIRA)
        }
    }
    
    private func getReadyPeripheral(_ deviceId: UUID) async throws -> Peripheral {
        if let peripheral = try await getPeripheral(deviceId) {
            if (peripheral.state != .connected ) {
                try await connect(peripheral)
            }
            
            try await makeReady(peripheral)
            return peripheral
        } else {
            throw BluetoothServiceError.peripheralNotFound
        }
    }
    
    func executeCommand(_ command: any DeviceCommand) async throws -> any DeviceNotification {
        try await errorBoundary {
            let peripheral = try await self.getReadyPeripheral(command.deviceId)
            return try await withTimeout(Self.timeoutDuration) {
                let commandDispatcher = CommandExecutor(peripheral: peripheral)
                return try await command.accept(isolation: self, commandDispatcher)
            }
        }
    }
    
    private func disconnectPeripheral(_ peripheral: Peripheral) async throws {
        Self.logger.debug("Disconnecting \(peripheral.identifier)")
        try await central.cancelPeripheralConnection(peripheral)
        try await peripheral.cancelAllOperations()
        Self.logger.debug("Disconnected \(peripheral.identifier)")
    }
    
    func disconnectAll() async throws {
        try await errorBoundary {
            Self.logger.debug("Disconnecting all peripherals")
            for peripheral in self.central.retrieveConnectedPeripherals(
                withServices: [Service.SERVICE_MIRA]
            ) {
                do {
                    try await self.disconnectPeripheral(peripheral)
                } catch {
                    Self.logger.debug("Failed to disconnect peripheral \(peripheral.identifier)")
                }
            }
            
            try await self.central.cancelAllOperations()
        }
    }
    
    func disconnect(_ deviceId: UUID) async throws {
        try await errorBoundary { [self] in
            if let peripheral = try await getPeripheral(deviceId) {
                try await disconnectPeripheral(peripheral)
            }
        }
    }
    
    func startScan() async throws {
        try await errorBoundary {
            Self.logger.debug("starting scan")
            
            defer {
                Self.logger.debug("scan finished")
            }

            try await self.ensureCentralReady()

            guard await !self.central.isScanning else {
                throw BluetoothServiceError.alreadyScanning
            }

            try self.modelContext.transaction {
                try self.modelContext.delete(model: ScanResult.self)
            }
            
            for await scanData in try await self.central.scanForPeripherals(withServices: [Service.SERVICE_MIRA]) {
                let peripheral = scanData.peripheral
                Self.logger.debug("Peripheral: \(peripheral.name ?? ""), \(scanData.advertisementData)")

                try self.modelContext.transaction {
                    self.modelContext.insert(
                        ScanResult(
                            id: peripheral.identifier,
                            name: peripheral.name ?? "Unknown"
                        )
                    )
                }
            }
        }
    }
    
    func stopScan() async throws {
        try await errorBoundary {
            try await self.ensureCentralReady()
            return try await withTimeout(Self.timeoutDuration) {
                if (await self.central.isScanning) {
                    Self.logger.debug("stopping scan")
                    await self.central.stopScan()
                    Self.logger.debug("stopped scan")
                }
            }
        }
    }
}


extension Service {
    public static let SERVICE_DEVICE_INFORMATION = CBUUID(string: "0000180A-0000-1000-8000-00805F9B34FB")
    public static let SERVICE_MIRA = CBUUID(string: "BCCB0001-CA66-11E5-88A4-0002A5D5C51B")
}

extension Peripheral {
    func showerService() -> Service? {
        return getService(uuid: Service.SERVICE_MIRA)
    }

    func deviceInformationService() -> Service? {
        return getService(uuid: Service.SERVICE_DEVICE_INFORMATION)
    }
    
    private func getService(uuid: CBUUID) -> Service? {
        return discoveredServices?.first(where: { $0.uuid == uuid })
    }
}


extension Characteristic {
    static let CHARACTERISTIC_WRITE = CBUUID(string: "BCCB0002-CA66-11E5-88A4-0002A5D5C51B")
    static let CHARACTERISTIC_NOTIFICATIONS = CBUUID(string: "BCCB0003-CA66-11E5-88A4-0002A5D5C51B")
    
    static let CHARACTERISTIC_MODEL_NUMBER = CBUUID(string: "00002A24-0000-1000-8000-00805F9B34FB")
    static let CHARACTERISTIC_SERIAL_NUMBER = CBUUID(string: "00002A25-0000-1000-8000-00805F9B34FB")
    static let CHARACTERISTIC_HARDWARE_REVISION = CBUUID(string: "00002A26-0000-1000-8000-00805F9B34FB")
    static let CHARACTERISTIC_FIRMWARE_REVISION = CBUUID(string: "00002A27-0000-1000-8000-00805F9B34FB")
    static let CHARACTERISTIC_MANUFACTURER_NAME = CBUUID(string: "00002A29-0000-1000-8000-00805F9B34FB")
}
