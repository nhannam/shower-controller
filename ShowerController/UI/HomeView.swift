//
//  HomeView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    private static let logger = LoggerFactory.logger(HomeView.self)

    @Environment(Toolbox.self) private var tools
    
    @State private var showPairing = false
    
    var body: some View {
        VStack {
            List {
                Section(
                    content: { ClientView() },
                    header: { Text("Application") }
                )
                
                PairedDeviceSectionView()
            }
        }
        .suspendable(onSuspend: suspendProcessing)
        .toolbar {
            ToolbarItem {
                Button(
                    action: { showPairing = true },
                    label: { Label("Find...", systemImage: "magnifyingglass") }
                )
            }
        }
        .sheet(isPresented: $showPairing) {
            PairingView()
        }
        .navigationDestination(for: PairedDeviceRoute.self) { route in
            DeviceView(device: route.device)
        }
        .navigationTitle("Shower Controller")
    }
    
    func suspendProcessing() {
        tools.submitJobWithErrorHandler {
            try await tools.bluetoothService.disconnectAll()
        }
    }
}

#Preview {
    Preview {
        HomeView()
    }
}
