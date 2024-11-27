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
                bluetoothService: MockBluetoothService(modelContainer: mockModelContainer)
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
    var asyncJobExecutor: AsyncJobExecutor = AsyncJobExecutor()
    var errorHandler: AlertingErrorHandler = AlertingErrorHandler()
    var navigationPath = NavigationPath()

    init(modelContainer: ModelContainer, bluetoothService: ManagedReentrancyBluetoothService) {
        self.modelContainer = modelContainer
        self.bluetoothService = bluetoothService
        self.deviceService = DeviceService(modelContainer: modelContainer, bluetoothService: bluetoothService)
        self.clientService = ClientService(modelContainer: modelContainer)
    }
    
    func alertOnError(_ job: @escaping @MainActor () async throws -> Void) async {
        await errorHandler.alertOnError(job)
    }
    
    func submitJob(_ job: @escaping @MainActor () async -> Void) {
        asyncJobExecutor.submit(job)
    }

    func submitJobWithErrorHandler(
        _ job: @escaping @MainActor () async throws -> Void,
        finally: (@MainActor () -> Void)? = nil
    ) {
        submitJob {
            await self.alertOnError(job)
            finally?()
        }
    }
    
    func startProcessing() async {
        Self.logger.debug("Starting async processing")
        await withTaskGroup(of: Void.self) { group in
            group.addTask(operation: bluetoothService.startProcessing)
            group.addTask(operation: asyncJobExecutor.start)
        }
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
