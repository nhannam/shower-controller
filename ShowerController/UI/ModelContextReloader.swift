//
//  ModelUpdatedMonitorViewModifier.swift
//  ShowerController
//
//  Created by Nigel Hannam on 16/11/2024.
//

import Foundation
import Combine
import SwiftData
import SwiftUICore

/*
 
 Workround for swiftdata not properly notifying the UI of changes
 persisted on another thread by a ModelActor.
 
 Part 1: The reloader monitors ModelContext.didSave events and loads the changed entities into
 the UI ModelContext.
 
 Part 2: The UI monitor triggers redraws when persistent entities of interest have been updated
 
 */

struct ModelContextReloader: ViewModifier {
    private static let logger = LoggerFactory.logger(ModelContextReloader.self)
    
    let modelUpdatedPublisher: ModelUpdatedPublisher
    
    func body(content: Content) -> some View {
        content
            .onReceive(modelUpdatedPublisher.publisher){ notification in
                if let userInfo = notification.userInfo {
                    checkPersistentIdentifiers("deleted", userInfo: userInfo)
                    checkPersistentIdentifiers("updated", userInfo: userInfo)
                    checkPersistentIdentifiers("inserted", userInfo: userInfo)
                }
            }
            .environment(modelUpdatedPublisher)
    }
    
    func fetch<Entity: PersistentModel>(predicate: Predicate<Entity>) {
        do {
            let _ = try modelUpdatedPublisher.modelContext.fetch(FetchDescriptor<Entity>(predicate: predicate))
        } catch {
            Self.logger.warning("Failed to reload \(String(describing: predicate))")
        }
    }
    
    func checkPersistentIdentifiers(_ type: String, userInfo: [AnyHashable: Any]) {
        if let modified = userInfo[type] as? [PersistentIdentifier] {
            for persistentIdentifier in modified {
                let entityName = persistentIdentifier.entityName
                switch entityName {
                case String(describing: Client.self):
                    fetch(predicate: #Predicate<Client> { $0.persistentModelID == persistentIdentifier })
                case String(describing: Device.self):
                    fetch(predicate: #Predicate<Device> { $0.persistentModelID == persistentIdentifier })
                case String(describing: Outlet.self):
                    fetch(predicate: #Predicate<Outlet> { $0.persistentModelID == persistentIdentifier })
                case String(describing: PairedClient.self):
                    fetch(predicate: #Predicate<PairedClient> { $0.persistentModelID == persistentIdentifier })
                case String(describing: Preset.self):
                    fetch(predicate: #Predicate<Preset> { $0.persistentModelID == persistentIdentifier })
                case String(describing: TechnicalInformation.self):
                    fetch(predicate: #Predicate<TechnicalInformation> { $0.persistentModelID == persistentIdentifier })
                default:
                    Self.logger.debug("Unknown entity name \(entityName)")
                }
            }
        }
    }
    
    @Observable
    class ModelUpdatedPublisher {
        let modelContext: ModelContext
        
        init(modelContext: ModelContext) {
            self.modelContext = modelContext
        }
        
        let publisher = NotificationCenter.default
            .publisher(for: ModelContext.didSave, object: nil)
            .receive(on: DispatchQueue.main)
    }

}

struct ModelUpdatedMonitorViewModifier: ViewModifier {
    private static let logger = LoggerFactory.logger(ModelUpdatedMonitorViewModifier.self)
    
    @Environment(ModelContextReloader.ModelUpdatedPublisher.self) private var modelUpdatedPublisher: ModelContextReloader.ModelUpdatedPublisher

    let persistentIdentifiers: [PersistentIdentifier]
    @Binding var updatedCounter: Int64
    
    func body(content: Content) -> some View {
        content
            .onReceive(modelUpdatedPublisher.publisher){ notification in
                if let userInfo = notification.userInfo {
                    if checkPersistentIdentifiers("deleted", userInfo: userInfo) ||
                        checkPersistentIdentifiers("updated", userInfo: userInfo) ||
                        checkPersistentIdentifiers("inserted", userInfo: userInfo) {
                        Self.logger.debug("Update counter incremented")
                        updatedCounter += 1
                    }
                }
            }
    }
    
    func checkPersistentIdentifiers(_ type: String, userInfo: [AnyHashable: Any]) -> Bool {
        if let modified = userInfo[type] as? [PersistentIdentifier] {
            for persistentIdentifier in modified {
                if persistentIdentifiers.contains(persistentIdentifier) {
                    return true
                }
            }
        }
        return false
    }
    
    struct RedrawTrigger: View {
        let updatedCounter: Int64
        
        var body: some View {
            if (updatedCounter < 0) {
                Text("Update Counter \(updatedCounter)")
            }
        }
    }

}


extension View {
    func modelContextReloader(_ modelContext: ModelContext) -> some View {
        modifier(
            ModelContextReloader(modelUpdatedPublisher: ModelContextReloader.ModelUpdatedPublisher(modelContext: modelContext))
        )
    }
    
    func monitoringUpdatesOf(
        _ peristentIdentifiers: [PersistentIdentifier],
        _ updatedCounter: Binding<Int64>
    ) -> some View {
        modifier(
            ModelUpdatedMonitorViewModifier(
                persistentIdentifiers: peristentIdentifiers,
                updatedCounter: updatedCounter
            )
        )
    }
}

extension Array {
    mutating func compactAppend(_ element: Element?) {
        if let element = element {
            self.append(element)
        }
    }
}
