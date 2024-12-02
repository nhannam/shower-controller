//
//  ShowerControllerApp.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI

@main
struct ShowerControllerApp: App {
    private static let logger = LoggerFactory.logger(ShowerControllerApp.self)
    
    @State private var mode: ToolboxMode = .live
    @State private var toolboxes: Toolboxes? = nil

    var body: some Scene {
        WindowGroup {
            Group {
                if let toolbox = toolboxes?.toolboxes[mode] {
                    MainNavigationStack(
                        mode: $mode,
                        tools: toolbox
                    )
                    .modelContainer(toolbox.modelContainer)
                    .task(id: mode, toolbox.startProcessing)
                }
            }
            .task {
                do {
                    toolboxes = try Toolboxes()
               } catch {
                   Self.logger.error("Failed to setup application \(error)")
                }
            }
        }
    }
}
