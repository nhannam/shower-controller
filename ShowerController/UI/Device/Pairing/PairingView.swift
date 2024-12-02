//
//  PairingView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI
import SwiftData

struct PairingView: View {
    private static let logger = LoggerFactory.logger(PairingView.self)
    
    @Environment(\.dismiss) private var dismiss
    @Environment(Toolbox.self) private var tools

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
        await tools.alertOnError {
            await stopScan()
            try await tools.bluetoothService.disconnectAll()
            try await tools.bluetoothService.startScan()
        }
        isScanning = false
    }
    
    func stopScan() async {
        await tools.alertOnError {
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
