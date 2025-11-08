//
//  ShowerControllerApp.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI

struct MainNavigationStack: View {
    private static let logger = LoggerFactory.logger(MainNavigationStack.self)
    
    @Binding var mode: ToolboxMode
    
    @Bindable var tools: Toolbox

    var body: some View {
        NavigationStack(path: $tools.navigationPath) {
            HomeView()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Picker("Mode", selection: $mode) {
                            Text("Live").tag(ToolboxMode.live)
                            Text("Mock").tag(ToolboxMode.mock)
                        }
                        .pickerStyle(.palette)
                        .fixedSize()
                    }
                }
        }
        .environment(tools)
        .monitorModelContextTransactions()
    }
}
