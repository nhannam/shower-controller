//
//  PairingView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI

struct PairingView: View {
    private static let logger = LoggerFactory.logger(PairingView.self)
    
    @Environment(\.dismiss) private var dismiss
    @Environment(Toolbox.self) private var tools

    @State private var errorHandler = ErrorHandler()
    @State private var isScanning = false

    var body: some View {
        NavigationStack {
            List {
                PairedDeviceSectionView()
                    .disabled(true)
                UnpairedDeviceSectionView(isScanning: isScanning)
            }
            .toolbar {
                ToolbarItem {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .navigationTitle("Pair Shower")
        }
        .suspendable(
            onSuspend: { isScanning = false },
            onResume: { isScanning = true }
        )
        .onDisappear(perform: { isScanning = false })
        .alertingErrorHandler(errorHandler)
        .task(startScan)
        .task(id: isScanning) {
            if isScanning {
                await startScan()
            } else {
                await stopScan()
            }
        }
    }
    
    func startScan() async {
        await errorHandler.handleError {
            await stopScan()
            try await tools.bluetoothService.disconnectAll()
            try await tools.bluetoothService.startScan()
        }
        isScanning = false
    }
    
    func stopScan() async {
        await errorHandler.handleError {
            Self.logger.debug("PairingView stopping scan")
            try await tools.bluetoothService.stopScan()
        }
    }
}

#Preview {
    Preview {
        PairingView()
    }
}
