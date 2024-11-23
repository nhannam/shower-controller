//
//  tools.swift
//  ShowerController
//
//  Created by Nigel Hannam on 06/11/2024.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class Toolbox {
    static let mainContextAuthor = "mainContextAuthor"
    
    enum Mode { case live, mock }
    var mode: Mode

    var navigationPath: NavigationPath

    var asyncJobs: AsyncJobs
    var errorHandler: AlertingErrorHandler

    private let liveTools: Tools
    private let mockTools: Tools
    
    var tools: Tools {
        switch mode {
        case .live:
            liveTools
        case .mock:
            mockTools
        }
    }
    
    var modelContainer: ModelContainer {
        return tools.modelContainer
    }
    
    var clientService: ClientService {
        tools.clientService
    }

    var deviceService: DeviceService {
        tools.deviceService
    }

    
    init(_ mode: Mode) throws {
        let liveModelContainer = try ModelContainer.create(isStoredInMemoryOnly: false)
        liveTools = Tools(
            modelContainer: liveModelContainer,
            bluetoothService: ManagedReentrancyBluetoothService(
                bluetoothService: AsyncBluetoothService(modelContainer: liveModelContainer)
            )
        )

        let mockModelContainer = try ModelContainer.create(isStoredInMemoryOnly: true)
        mockTools = Tools(
            modelContainer: mockModelContainer,
            bluetoothService: ManagedReentrancyBluetoothService(
                bluetoothService: MockBluetoothService(modelContainer: mockModelContainer)
            )
        )
        
        _mode = mode
        _asyncJobs = AsyncJobs()
        _errorHandler = AlertingErrorHandler()
        _navigationPath = NavigationPath()
    }
    
    func alertOnError(_ job: @escaping @MainActor () async throws -> Void) async {
        await errorHandler.alertOnError(job)
    }
    
    func submitJob(_ job: @escaping @MainActor () async -> Void) {
        asyncJobs.submit(job)
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

    func navigateHome() {
        navigationPath.removeLast(navigationPath.count)
    }

    func startBluetoothProcessing() async {
        await tools.bluetoothService.startProcessing()
    }
    
    class Tools {
        let modelContainer: ModelContainer
        let bluetoothService: ManagedReentrancyBluetoothService
        let deviceService: DeviceService
        let clientService: ClientService

        init(modelContainer: ModelContainer, bluetoothService: ManagedReentrancyBluetoothService) {
            self.modelContainer = modelContainer
            self.bluetoothService = bluetoothService
            self.deviceService = DeviceService(modelContainer: modelContainer, bluetoothService: bluetoothService)
            self.clientService = ClientService(modelContainer: modelContainer)
        }
    }
}

extension ModelContainer {
    @MainActor
    static func create(isStoredInMemoryOnly: Bool) throws -> ModelContainer {
        let modelContainer = try ModelContainer(
            for:
                Client.self,
                Device.self,
                TransactionMonitorPosition.self,
            configurations: ModelConfiguration(
                isStoredInMemoryOnly: isStoredInMemoryOnly
            )
        )
        modelContainer.mainContext.author = Toolbox.mainContextAuthor
        return modelContainer
    }
}
