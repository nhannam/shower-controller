//
//  BluetoothService.swift
//  ShowerController
//
//  Created by Nigel Hannam on 19/11/2024.
//

import Foundation

enum BluetoothServiceError: Error {
    case bluetoothUnavailable
    case cannotConnectToDevice
    case cannotMakeDeviceReady
    case timeoutSendingCommand
    case timeoutWaitingForResponse

    case alreadyScanning
    case deviceNotFound
    case clientNotFound
    case notPaired
    case operationTimedOut
    case internalError

}

protocol BluetoothService: Actor {
    func dispatchCommand(_ command: DeviceCommand) async throws
    func dispatchCommands(_ commands: [DeviceCommand]) async throws
    func disconnectAll() async throws
    func disconnect(_ deviceId: UUID) async throws
    func startScan() async throws
    func stopScan() async throws
    func requestDeviceInformation(_ deviceId: UUID) async throws
}

extension BluetoothService {
    func dispatchCommands(_ commands: [DeviceCommand]) async throws {
        for command in commands {
            try await dispatchCommand(command)
        }
    }
}
