//
//  BluetoothServiceError.swift
//  ShowerController
//
//  Created by Nigel Hannam on 10/11/2024.
//

import Foundation

extension BluetoothServiceError: LocalizedError {
    var errorDescription: String? {
        return switch self {
        case .bluetoothUnavailable:
            "Bluetooth Unavailable"
        case .peripheralNotFound, .cannotConnectToPeripheral, .cannotMakePeripheralReady:
            "Cannot Contact Device"
        case .notificationNotReceived:
            "Device Not Responding"
        case .timedOut:
            "Timed Out"
        default:
            "Uncategorized Error"
        }
    }
    
    var failureReason: String? {
        return switch self {
        case .bluetoothUnavailable:
            "Bluetooth not available or permission not granted to application"
        case .peripheralNotFound:
            "Could not find the device"
        case .cannotConnectToPeripheral:
            "Could not connect to the device"
        case .cannotMakePeripheralReady:
            "Failed to initialise the connected device"
        case .notificationNotReceived:
            "Pairing may have been removed by another client"
        case .timedOut:
            "Timed out when making a request to the device"
        default:
            "Unknown reason"
        }
    }

    var recoverySuggestion: String? {
        return switch self {
        case .bluetoothUnavailable:
            "Check bluetooth is turned on and the application has been granted permission"
        case .peripheralNotFound, .cannotConnectToPeripheral:
            "Check you are in range of the device"
        case .notificationNotReceived:
            "If the problem persists, try deleting an re-pairing"
        case .timedOut:
            "Try again"
        default:
            nil
        }
    }
}
