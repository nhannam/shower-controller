//
//  DataExtension.swift
//  ShowerController
//
//  Created by Nigel Hannam on 24/10/2024.
//

import Foundation
import CRC

public extension Data {
    private static let logger = LoggerFactory.logger(Data.self)

    init(bytesFrom: UInt16) {
        var source = bytesFrom
        self.init(bytes: &source, count: MemoryLayout<UInt16>.size)
    }
    
    func withCrc(clientSecret: Data) -> Data {
        let payloadWithClientSecret = Data(self) + clientSecret
        let checksum = CRC16.ccitt_false.calculate(for: payloadWithClientSecret)
        
        var payloadWithCrc = Data(self)
        payloadWithCrc.append(Data(bytesFrom: checksum.bigEndian))
        
        return payloadWithCrc
    }

    func withPaddingTo(length: Int) -> Data {
        var padded = Data(self)
        padded.append(Data(count: length - self.count))
        return padded
    }

    var hexDescription: String {
        return reduce("") {$0 + String(format: "%02x ", $1)}
    }
}


extension UInt16 {
    init?(bigEndian: Data) {
        if bigEndian.count == 2 {
            self.init(UInt16(bigEndian[0]) << 8 | UInt16(bigEndian[1]))
        } else {
            return nil
        }
    }
}
