//
//  DataAccumulator.swift
//  ShowerController
//
//  Created by Nigel Hannam on 05/11/2024.
//

import Foundation

class DataAccumulator {
    private static let logger = LoggerFactory.logger(DataAccumulator.self)

    private let clientSlot: UInt8
    private var accumulatedData: Data? = nil
    
    init(clientSlot: UInt8) {
        self.clientSlot = clientSlot
    }
    
    func accumulate(_ data: Data) -> Data? {
        Self.logger.debug("Notification data received: \(data.hexDescription)")

        if var accumulatedData {
            accumulatedData.append(data)
            self.accumulatedData = accumulatedData
        } else {
            guard data.starts(with: [ ProtocolConstants.notificationClientSlotBase + clientSlot, 0x01 ]) else {
                Self.logger.warning("Unexpected data at start of notification: \(data.hexDescription)")
                return nil
            }
            accumulatedData = data
        }
        
        if let accumulatedData {
            if isComplate(accumulated: accumulatedData) {
                self.accumulatedData = nil
                return accumulatedData
            }
        }
        
        return nil
    }

    private func isComplate(accumulated: Data) -> Bool {
        let accumulatedLength = accumulated.count
        let expectedLength = accumulated[2] + 3
        if (accumulatedLength < expectedLength) {
            return false
        } else {
            return true
        }
    }
}
