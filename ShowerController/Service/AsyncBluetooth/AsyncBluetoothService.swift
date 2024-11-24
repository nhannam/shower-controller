//
//  AsyncBluetoothService.swift
//  ShowerController
//
//  Created by Nigel Hannam on 04/11/2024.
//

import Foundation
@preconcurrency import CoreBluetooth
@preconcurrency import Combine
import SwiftData
import AsyncAlgorithms
import AsyncBluetooth

// @ModelActor creates a single arg init, which prevents us passing the BluetoothService in
actor AsyncBluetoothService: ModelActor, BluetoothService {
    private static let logger = LoggerFactory.logger(AsyncBluetoothService.self)
    private static let author = "AsyncBluetoothService"

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

    private func errorBoundary<R: Sendable>(@_inheritActorContext _ block: @escaping @Sendable () async throws -> R?) async throws -> R? {
        do {
            return try await block()
        } catch let error as BluetoothServiceError {
            throw error
        } catch is TimeoutError {
            throw BluetoothServiceError.operationTimedOut
        } catch let cancellationError as CancellationError {
            Self.logger.warning("Task cancellation trapped by error boundary: \(cancellationError)")
        } catch BluetoothError.bluetoothUnavailable(_) {
            throw BluetoothServiceError.bluetoothUnavailable
        } catch BluetoothError.connectingInProgress, BluetoothError.disconnectingInProgress,
                BluetoothError.cancelledConnectionToPeripheral {
            throw BluetoothServiceError.cannotConnectToDevice
        } catch BluetoothError.errorConnectingToPeripheral(_) {
            throw BluetoothServiceError.cannotConnectToDevice
        } catch BluetoothError.characteristicNotFound {
            throw BluetoothServiceError.cannotMakeDeviceReady
        } catch BluetoothError.operationCancelled {
            Self.logger.warning("Bluetooth operation cancelled")
        } catch {
            Self.logger.debug("Unexpected error: \(error)")
            throw BluetoothServiceError.internalError
        }
        
        return nil
    }
    
    private func findDeviceById(_ id: UUID) throws -> Device? {
        let findById = FetchDescriptor<Device>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(findById).first
    }
    
    private func getDeviceById(_ id: UUID) throws -> Device {
        do {
            if let device = try findDeviceById(id) {
                return device
            } else {
                throw BluetoothServiceError.deviceNotFound
            }
        }
    }
    
    private func getClient() throws -> Client {
        do {
            let findAll = FetchDescriptor<Client>()
            if let client = try modelContext.fetch(findAll).first {
                return client
            } else {
                throw BluetoothServiceError.clientNotFound
            }
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
    
    private func makeReady(_ peripheral: Peripheral) async throws {
        try await withTimeout(
            Self.timeoutDuration,
            error: BluetoothServiceError.cannotMakeDeviceReady
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
    
    private func getConnectedPeripheral(_ deviceId: UUID) async throws -> Peripheral? {
        let peripheral = try await getPeripheral(deviceId)
        if let peripheral {
            if (peripheral.state != .connected ) {
                try await withTimeout(
                    Self.timeoutDuration,
                    error: BluetoothServiceError.cannotConnectToDevice
                ) {
                    try await self.central.connect(peripheral)
                }
                
            }
            
            try await makeReady(peripheral)
        }
        return peripheral
    }
    
    func dispatchCommand(_ command: DeviceCommand) async throws {
        try await errorBoundary {
            return try await withTimeout(Self.timeoutDuration) { [self] in
                let device = try getDeviceById(command.deviceId)
                if let peripheral = try await getConnectedPeripheral(device.id) {
                    
                    let dataClientSlot = switch command.self {
                    case is PairDevice:
                        UInt8(0x00)
                    default:
                        if let pairedClientSlot = device.clientSlot {
                            pairedClientSlot
                        } else {
                            throw BluetoothServiceError.notPaired
                        }
                    }
                    
                    let notificationData = PublisherAsyncSequence<Data>(
                        valuesPublisher: await peripheral.characteristicValueUpdatedPublisher
                            .filter { $0.characteristic.uuid == Characteristic.CHARACTERISTIC_NOTIFICATIONS }
                            .compactMap(\.value)
                    )
                    let notificationParser = NotificationParser()
                    
                    let clientSecret = try getClient().secret
                    let commandDispatcher = CommandDispatcher(peripheral: peripheral, dataClientSlot: dataClientSlot, clientSecret: clientSecret)
                    
                    try await withTimeout(
                        Self.timeoutDuration,
                        error: BluetoothServiceError.timeoutSendingCommand
                    ) {
                        try await command.accept(commandDispatcher)
                    }
                    
                    let dataAccumulator = DataAccumulator(clientSlot: dataClientSlot)
                    
                    try await withTimeout(
                        Self.timeoutDuration,
                        error: BluetoothServiceError.timeoutWaitingForResponse
                    ) {
                        notificationLoop: for await notification in notificationData
                            .compactMap({ data in await dataAccumulator.accumulate(data) })
                            .compactMap({ data in
                                notificationParser.parseNotification(data, command: command)
                            }) {
                            if try await command.accept(IsExpectedNotificationTypeVisitor(notification)) {
                                try await self.dispatchNotification(notification: notification)
                                break notificationLoop
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func dispatchNotification(notification: DeviceNotification) async throws {
        try modelContext.transaction {
            let device = try getDeviceById(notification.deviceId)
            notification.accept(DeviceNotificatonApplier(device: device, modelContext: modelContext))
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
        try await errorBoundary {
            if let peripheral = try await self.getPeripheral(deviceId) {
                try await self.disconnectPeripheral(peripheral)
            }
        }
    }
    
    func startScan() async throws {
        try await errorBoundary {
            Self.logger.debug("starting scan")
            
            defer {
                Self.logger.debug("scan finished")
            }
            
            guard await !self.central.isScanning else {
                throw BluetoothServiceError.alreadyScanning
            }
            
            try await self.ensureCentralReady()
            
            for await scanData in try await self.central
                .scanForPeripherals(withServices: [Service.SERVICE_MIRA]) {
                try self.modelContext.transaction {
                    let peripheral = scanData.peripheral
                    Self.logger.debug("Peripheral: \(peripheral.name ?? ""), \(scanData.advertisementData)")
                    if try self.findDeviceById(peripheral.identifier) == nil {
                        self.modelContext.insert(
                            Device(
                                id: peripheral.identifier,
                                name: peripheral.name ?? "Unknown",
                                outlets: [
                                    Outlet(outletSlot: Outlet.outletSlot0, type: .overhead),
                                    Outlet(outletSlot: Outlet.outletSlot1, type: .bath)
                                ]
                            )
                        )
                    }
                }
            }
        }
    }
    
    func stopScan() async throws {
        try await errorBoundary {
            return try await withTimeout(Self.timeoutDuration) {
                if (await self.central.isScanning) {
                    Self.logger.debug("stopping scan")
                    try await self.ensureCentralReady()
                    await self.central.stopScan()
                    Self.logger.debug("stopped scan")
                }
            }
        }
    }
    
    func requestDeviceInformation(_ deviceId: UUID) async throws {
        try await errorBoundary {
            return try await withTimeout(Self.timeoutDuration) {
                if let peripheral = try await self.getConnectedPeripheral(deviceId) {
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
                    
                    try await self.dispatchNotification(
                        notification: DeviceInformationNotification(
                            deviceId: deviceId,
                            manufacturerName: manufacturerName,
                            modelNumber: modelNumber,
                            hardwareRevision: hardwareRevision?.hexDescription ?? "",
                            firmwareRevision: firmwareRevision?.hexDescription ?? "",
                            serialNumber: serialNumber?.hexDescription ?? ""
                        )
                    )
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
