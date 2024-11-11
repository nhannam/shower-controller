//
//  ShowerControllerApp.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI
import SwiftData

@main
struct ShowerControllerApp: App {
    private static let logger = LoggerFactory.logger(ShowerControllerApp.self)
    
    @State private var tools: Toolbox? = nil

    var body: some Scene {
        WindowGroup {
            Group {
                if let tools {
                    @Bindable var tools = tools
                    Group {
                        NavigationStack(path: $tools.navigationPath) {
                            HomeView()
                                .toolbar {
                                    ToolbarItem(placement: .bottomBar) {
                                        Picker(selection: $tools.mode, label: Text("Mode")) {
                                            Text("Live").tag(Toolbox.Mode.live)
                                            Text("Mock").tag(Toolbox.Mode.mock)
                                        }
                                        .pickerStyle(.segmented)
                                    }
                                }
                        }
                        .task {
                            await tools.deviceService.startProcessing()
                        }
                        .environment(tools)
                        .modelContextReloader(tools.modelContainer.mainContext)
                    }
                    .modelContainer(tools.modelContainer)
                    .alertingErrorHandler(tools.errorHandler)
                    .asyncJobExecutor(tools.asyncJobs)
                }
            }
            .task {
                do {
                    tools = try Toolbox(.live)
               } catch {
                   Self.logger.error("Failed to setup application \(error)")
                }
            }
        }
    }
}
