//
//  ShowerControllerApp.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI
import SwiftData

struct MainNavigationStack: View {
    private static let logger = LoggerFactory.logger(MainNavigationStack.self)
    
    @Binding var mode: ToolboxMode
    
    @Bindable var tools: Toolbox

    var body: some View {
        NavigationStack(path: $tools.navigationPath) {
            HomeView()
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Picker(selection: $mode, label: Text("Mode")) {
                            Text("Live").tag(ToolboxMode.live)
                            Text("Mock").tag(ToolboxMode.mock)
                        }
                        .pickerStyle(.segmented)
                    }
                }
        }
        .environment(tools)
        .monitorModelContextTransactions()
        .alertingErrorHandler(tools.errorHandler)
    }
}
