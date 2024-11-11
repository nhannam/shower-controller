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
        case .cannotConnectToDevice, .cannotMakeDeviceReady:
            "Cannot Contact Device"
        case .operationTimedOut:
            "Timed Out"
        default:
            "Uncategorized Error"
        }
    }
    
    var failureReason: String? {
        return switch self {
        case .bluetoothUnavailable:
            "Bluetooth not available or permission not granted to application"
        case .cannotConnectToDevice:
            "Could not connect to the device"
        case .cannotMakeDeviceReady:
            "Failed to initialise the connected device"
        case .operationTimedOut:
            "Timed out when making a request to the device"
        default:
            "Unknown reason"
        }
    }

    var recoverySuggestion: String? {
        return switch self {
        case .bluetoothUnavailable:
            "Check bluetooth is turned on and the application has been granted permission"
        case .cannotConnectToDevice:
            "Check you are in range of the device"
        case .operationTimedOut:
            "Try again"
        default:
            nil
        }
    }
}
