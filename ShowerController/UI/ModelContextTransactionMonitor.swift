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
    
    let publisher = NotificationCenter.default
        .publisher(for: ModelContext.didSave, object: nil)
        .receive(on: DispatchQueue.main)
    
    func body(content: Content) -> some View {
        content
            .onReceive(publisher){ notification in
                do {
                    try catchUp()
                } catch {
                    Self.logger.warning("Failed to catch up with database changes: \(error)")
                }
            }
    }
    
    func catchUp() throws {
        let position = try modelContext.fetch(
            FetchDescriptor<TransactionMonitorPosition>(
                predicate: #Predicate<TransactionMonitorPosition> { position in true }
            )
        ).first
        
        let positionToken = position?.token
        let author = modelContext.author
        
        let historyDescriptor = if let positionToken {
            HistoryDescriptor<DefaultHistoryTransaction>(predicate: #Predicate { $0.token > positionToken && $0.author != author })
        } else {
            HistoryDescriptor<DefaultHistoryTransaction>(predicate: #Predicate { $0.author != author })
        }
        
        if let lastProcessedTransaction = try processTransactions(historyDescriptor: historyDescriptor) {
            try modelContext.transaction {
                if let position {
                    position.token = lastProcessedTransaction
                } else {
                    modelContext.insert(TransactionMonitorPosition(token: lastProcessedTransaction))
                }
            }
        }
    }
    
    func processTransactions(historyDescriptor: HistoryDescriptor<DefaultHistoryTransaction>) throws -> DefaultHistoryToken? {
        let txns = try modelContext.fetchHistory(historyDescriptor)
        var lastTransaction: DefaultHistoryToken? = nil
        
        if !txns.isEmpty {
            Self.logger.info("Catching up with \(txns.count) transactions")
            for txn in txns {
                
                // Fire model update events
                for change in txn.changes {
                    switch change {
                    case .insert(let insert):
                        Self.logger.debug("Insert received for \(String(describing: insert.changedPersistentIdentifier))")

                    case .update(let update as DefaultHistoryUpdate<Client>):
                        try handleUpdate(historyUpdate: update)
                    case .update(let update as DefaultHistoryUpdate<Device>):
                        try handleUpdate(historyUpdate: update)
                    case .update(let update as DefaultHistoryUpdate<Outlet>):
                        try handleUpdate(historyUpdate: update)
                    case .update(let update as DefaultHistoryUpdate<PairedClient>):
                        try handleUpdate(historyUpdate: update)
                    case .update(let update as DefaultHistoryUpdate<Preset>):
                        try handleUpdate(historyUpdate: update)
                    case .update(let update as DefaultHistoryUpdate<ScanResult>):
                        try handleUpdate(historyUpdate: update)
                    case .update(let update as DefaultHistoryUpdate<TechnicalInformation>):
                        try handleUpdate(historyUpdate: update)
                    case .update(let update as DefaultHistoryUpdate<UserInterface>):
                        try handleUpdate(historyUpdate: update)
                    case .update(let update as DefaultHistoryUpdate<UserInterfaceButton>):
                        try handleUpdate(historyUpdate: update)

                    case .update(_):
                        Self.logger.debug("Update received for \(String(describing: change.changedPersistentIdentifier))")
                        
                    case .delete(let delete):
                        Self.logger.debug("Delete received for \(String(describing: delete.changedPersistentIdentifier))")
                        
                    @unknown default:
                        Self.logger.debug("Unknown change received for \(String(describing: change.changedPersistentIdentifier))")
                    }
                    
                    lastTransaction = txn.token
                }
            }
            Self.logger.debug("Caught up transactions to \(String(describing: lastTransaction))")
        }
        
        return lastTransaction
    }
    
    func handleUpdate<Entity: PersistentModel>(historyUpdate: DefaultHistoryUpdate<Entity>) throws {
        let persistentIdentifier = historyUpdate.changedPersistentIdentifier
        let fetchDescriptor = FetchDescriptor<Entity>(predicate: #Predicate {
            $0.persistentModelID == persistentIdentifier
        })
        
        let _ = try modelContext.fetch(fetchDescriptor)
    }
}

extension View {
    func monitorModelContextTransactions() -> some View {
        modifier(ModelContextTransactionMonitor())
    }
}
