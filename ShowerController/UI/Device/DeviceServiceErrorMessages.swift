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
        case .internalError:
            "Internal Error"
        }
    }
    
    var failureReason: String? {
        return switch self {
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
