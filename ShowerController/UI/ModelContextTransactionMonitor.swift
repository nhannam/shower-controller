//
//  ModelContextTransactionMonitor.swift
//  ShowerController
//
//  Created by Nigel Hannam on 16/11/2024.
//

import Foundation
import Combine
import SwiftData
import SwiftUI

/*
 
 Workround for swiftdata not properly notifying the UI of changes
 persisted on another thread by a ModelActor.

 Every time it receives an indication that a modelContext made a save, it
 checks for transactions that have been written by a modelContext other than the
 mainContext (relies on setting a different 'author' on every modelContext)
 
 Each transaction contains information about the changes that were made, and this is
 used to fire ObservationRegistrar willSet / didSet events as will have happened
 but were not seen because they were on object instances not visible to the UI
 
 There a couple of big switch statements that would be nice to get rid of, but the
 type checking is causing some difficulties.
 
 */

struct ModelContextTransactionMonitor: ViewModifier {
    private static let logger = LoggerFactory.logger(ModelContextTransactionMonitor.self)
    
    @Environment(\.modelContext) private var modelContext: ModelContext
    
    func body(content: Content) -> some View {
        content
            .task {
                for await msg in NotificationCenter.default.messages(
                    for: Device.DeviceDidUpdate.self
                ) {
                    do {
                        let _ = try fetchDevice(msg.deviceId)
                    } catch {
                        
                    }
                }
            }
    }
        
    func fetchDevice(_ id: UUID) throws {
        Self.logger.warning("Fetching device: \(id)")
        
        var fetchDescriptor = FetchDescriptor<Device>(predicate: #Predicate {
            $0.id == id
        })
        fetchDescriptor.relationshipKeyPathsForPrefetching = [
            \.outlets, \.pairedClients, \.presets, \.technicalInformation, \.userInterface, \.userInterface?.buttons
            
        ]
        
        let _ = try modelContext.fetch(fetchDescriptor)
    }
}

extension View {
    func monitorModelContextTransactions() -> some View {
        modifier(ModelContextTransactionMonitor())
    }
}
