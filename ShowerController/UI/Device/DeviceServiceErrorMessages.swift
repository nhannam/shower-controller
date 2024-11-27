//
//  DeviceServiceErrorMessages.swift
//  ShowerController
//
//  Created by Nigel Hannam on 10/11/2024.
//

import Foundation

extension DeviceServiceError: LocalizedError {
    var errorDescription: String? {
        return switch self {
        case .deviceNotFound:
            "Device Not Found"
        case .clientNotFound:
            "Client Not Found"
        case .deviceNotPaired:
            "Device Not Paired"
        case .commandFailed:
            "Operation Failed"
        case .internalError:
            "Internal Error"
        }
    }
    
    var failureReason: String? {
        return switch self {
        case .deviceNotFound:
            "Device rejected the request"
        default:
            "Unknown reason"
        }
    }

    var recoverySuggestion: String? {
        return switch self {
        default:
            nil
        }
    }
}
