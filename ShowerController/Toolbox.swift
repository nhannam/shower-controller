//
//  tools.swift
//  ShowerController
//
//  Created by Nigel Hannam on 06/11/2024.
//

import Foundation
import SwiftData
import SwiftUI

enum ToolboxMode { case live, mock }


@MainActor
@Observable
class Toolboxes {
    static let mainContextAuthor = "mainContextAuthor"
    
    var toolboxes: [ToolboxMode:Toolbox]

    init() throws {
        let liveModelContainer = try ModelContainer.create(isStoredInMemoryOnly: false)
        let liveTools = Toolbox(
            modelContainer: liveModelContainer,
            bluetoothService: ManagedReentrancyBluetoothService(
                bluetoothService: AsyncBluetoothService(modelContainer: liveModelContainer)
            )
        )

        let mockModelContainer = try ModelContainer.create(isStoredInMemoryOnly: true)
        let mockTools = Toolbox(
            modelContainer: mockModelContainer,
            bluetoothService: ManagedReentrancyBluetoothService(
                bluetoothService: MockBluetoothService(
                    modelContainer: mockModelContainer,
                    // Use a separate model container for the mock peripherals
                    mockPeripherals: try MockPeripherals(modelContainer: try ModelContainer.create(isStoredInMemoryOnly: true))
                )
            )
        )
        
        _toolboxes = [
            .live: liveTools,
            .mock: mockTools
        ]
    }

}

@MainActor
@Observable
class Toolbox {
    private static let logger = LoggerFactory.logger(Toolbox.self)
    
    let modelContainer: ModelContainer
    let bluetoothService: ManagedReentrancyBluetoothService
    let deviceService: DeviceService
    let clientService: ClientService
    var navigationPath = NavigationPath()

    init(modelContainer: ModelContainer, bluetoothService: ManagedReentrancyBluetoothService) {
        self.modelContainer = modelContainer
        self.bluetoothService = bluetoothService
        self.deviceService = DeviceService(modelContainer: modelContainer, bluetoothService: bluetoothService)
        self.clientService = ClientService(modelContainer: modelContainer)
    }
    
    func startProcessing() async {
        Self.logger.debug("Starting async processing")
        await bluetoothService.startProcessing()
        Self.logger.debug("Finished async processing")
    }
    
    func navigateHome() {
        navigationPath.removeLast(navigationPath.count)
    }
}

extension ModelContainer {
    @MainActor
    static func create(isStoredInMemoryOnly: Bool) throws -> ModelContainer {
        let modelContainer = try ModelContainer(
            for:
                Client.self,
                Device.self,
                ScanResult.self,
                TransactionMonitorPosition.self,
            configurations: ModelConfiguration(
                isStoredInMemoryOnly: isStoredInMemoryOnly
            )
        )
        modelContainer.mainContext.author = Toolboxes.mainContextAuthor
        return modelContainer
    }
}
