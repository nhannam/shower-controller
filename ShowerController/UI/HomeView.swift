//
//  HomeView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI

struct HomeView: View {
    private static let logger = LoggerFactory.logger(HomeView.self)

    @Environment(Toolbox.self) private var tools
    
    @State private var errorHandler = ErrorHandler()
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showPairing = true }) {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
        .alertingErrorHandler(errorHandler)
        .suspendable(onSuspend: suspendProcessing)
        .sheet(isPresented: $showPairing) {
            PairingView()
        }
        .navigationDestination(for: PairedDeviceRoute.self) { route in
            DeviceView(device: route.device)
        }
        .navigationTitle("Shower Controller")
    }
    
    func suspendProcessing() async {
        await errorHandler.handleError {
            try await tools.bluetoothService.disconnectAll()
        }
    }
}

#Preview {
    Preview {
        HomeView()
    }
}
