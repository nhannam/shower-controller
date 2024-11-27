//
//  BluetoothService.swift
//  ShowerController
//
//  Created by Nigel Hannam on 19/11/2024.
//

import Foundation

enum BluetoothServiceError: Error {
    case bluetoothUnavailable
    case peripheralNotFound
    case cannotConnectToPeripheral
    case cannotMakePeripheralReady
    case notificationNotReceived

    case alreadyScanning
    case cancelled
    case timedOut
    case internalError

}

protocol BluetoothService: Actor {
    func executeCommand(_ command: DeviceCommand) async throws -> DeviceNotification
    func disconnectAll() async throws
    func disconnect(_ deviceId: UUID) async throws
    func startScan() async throws
    func stopScan() async throws
}
