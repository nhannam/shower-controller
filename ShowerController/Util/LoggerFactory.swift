//
//  LoggerFactory.swift
//  ShowerController
//
//  Created by Nigel Hannam on 28/10/2024.
//

import Foundation
import OSLog

struct LoggerFactory{
    static func logger(_ type: Any.Type) -> Logger {
        return Logger(subsystem: Bundle.main.bundleIdentifier!, category: String(describing: type))
    }
}
