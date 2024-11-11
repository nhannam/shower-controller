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
    func dispatchCommands(_ commands: [DeviceCommand]) async throws
    func startProcessing() async
    func disconnectAll() async throws
    func disconnect(_ deviceId: UUID) async throws
    func startScan() async throws
    func stopScan() async throws
    func requestDeviceInformation(_ deviceId: UUID) async throws
}
