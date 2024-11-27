//
//  ManagedReentrancyBluetoothService.swift
//  ShowerController
//
//  Created by Nigel Hannam on 22/11/2024.
//

import Foundation

actor ManagedReentrancyBluetoothService: BluetoothService {
    private static let logger = LoggerFactory.logger(ManagedReentrancyBluetoothService.self)

    // channel used to prevent interleaving of bluetooth operations
    private let executionChannel: AsyncRequestResponseChannel = AsyncRequestResponseChannel()
    
    private let bluetoothService: BluetoothService
    
    init(bluetoothService: BluetoothService) {
        self.bluetoothService = bluetoothService
    }

    private func errorBoundary<Response: Sendable>(@_inheritActorContext _ block: @escaping @Sendable () async throws -> Response) async throws -> Response {
        do {
            return try await block()
        } catch let error as BluetoothServiceError {
            throw error
        } catch is CancellationError {
            throw BluetoothServiceError.cancelled
        } catch AsyncRequestResponseChannelError.noResponse {
            throw BluetoothServiceError.cancelled
        } catch {
            Self.logger.debug("Unexpected error: \(error)")
            throw BluetoothServiceError.internalError
        }
    }

    func executeCommand(_ command: any DeviceCommand) async throws -> any DeviceNotification {
        try await errorBoundary {
            try await self.executionChannel.submit {
                return try await self.bluetoothService.executeCommand(command)
            }
        }
    }
    
    func startProcessing() async {
        await executionChannel.start()
    }

    func disconnectAll() async throws {
        try await errorBoundary {
            try await self.executionChannel.submit {
                try await self.bluetoothService.disconnectAll()
            }
        }
    }
    
    func disconnect(_ deviceId: UUID) async throws {
        try await errorBoundary {
            try await self.executionChannel.submit {
                try await self.bluetoothService.disconnect(deviceId)
            }
        }
    }
    
    func startScan() async throws {
        try await errorBoundary {
            try await self.bluetoothService.startScan()
        }
    }
    
    func stopScan() async throws {
        try await errorBoundary {
            try await self.bluetoothService.stopScan()
        }
    }
}
