//
//  Client.swift
//  ShowerController
//
//  Created by Nigel Hannam on 23/10/2024.
//

import Foundation
import SwiftData

@Model
class PairedClient {
    #Unique<PairedClient>([\.device, \.clientSlot])
    
    @Relationship
    var device: Device?

    private(set) var clientSlot: UInt8
    fileprivate(set) var name: String
    
    init(clientSlot: UInt8, name: String) {
        self.clientSlot = clientSlot
        self.name = name
    }
    
    func isSlot(_ clientSlot: UInt8) -> Bool {
        return self.clientSlot == clientSlot
    }
}

class  PairedClientNotificationApplier: ClientNotificationVisitor {
    private let pairedClient: PairedClient
    
    init(_ pairedClient: PairedClient) {
        self.pairedClient = pairedClient
    }
    
    func visit(_ notification: PairedClientDetailsNotification) {
        if let name = notification.name {
            pairedClient.name = name
        }
    }
}
