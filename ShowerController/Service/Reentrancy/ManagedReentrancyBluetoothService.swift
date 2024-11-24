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
    private let executionChannel: AsyncRequestResponseChannel<Void> = AsyncRequestResponseChannel()
    
    private let bluetoothService: BluetoothService
    
    init(bluetoothService: BluetoothService) {
        self.bluetoothService = bluetoothService
    }

    private func errorBoundary(@_inheritActorContext _ block: @escaping @Sendable () async throws -> Void) async throws {
        do {
            try await block()
        } catch let error as BluetoothServiceError {
            throw error
        } catch let cancellationError as CancellationError {
            Self.logger.warning("Task cancellation trapped by error boundary: \(cancellationError)")
        } catch AsyncRequestResponseChannelError.noResponse {
            Self.logger.debug("No response from AsyncRequestResponseChannel - likely a task was cancelled")
        } catch {
            Self.logger.debug("Unexpected error: \(error)")
            throw BluetoothServiceError.internalError
        }
    }

    func dispatchCommand(_ command: any DeviceCommand) async throws {
        try await errorBoundary {
            try await self.executionChannel.submit {
                try await self.bluetoothService.dispatchCommand(command)
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
    
    func requestDeviceInformation(_ deviceId: UUID) async throws {
        try await errorBoundary {
            try await self.executionChannel.submit {
                try await self.bluetoothService.requestDeviceInformation(deviceId)
            }
        }
    }
}
