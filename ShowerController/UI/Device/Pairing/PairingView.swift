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
            asyncJobExecutor: tools.asyncJobExecutor,
            onSuspend: stopScan,
            onResume: startScan
        )
        .onDisappear(perform: { tools.submitJob(stopScan) })
        .task(startScan)
    }
    
    func startScan() async {
        await tools.alertOnError {
            await stopScan()
            isScanning = true
            try await tools.bluetoothService.startScan()
        }
        isScanning = false
    }
    
    func stopScan() async {
        await tools.alertOnError {
            Self.logger.debug("PairingView stopping scan")
            try await tools.bluetoothService.stopScan()
            isScanning = false
        }
    }
}

#Preview {
    Preview {
        PairingView()
    }
}
