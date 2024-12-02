//
//  PairDeviceButton.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI
import SwiftData

struct PairDeviceButton: View {
    private static let logger = LoggerFactory.logger(PairDeviceButton.self)
    
    @Environment(Toolbox.self) private var tools

    var scanResult: ScanResult
    
    @State private var isSubmitted = false

    var body: some View {
        Button(
            action: { isSubmitted = true },
            label: {
                Label(
                    title: { Text(scanResult.name) },
                    icon: {
                        if (isSubmitted) {
                            ProgressView()
                        } else {
                            Image(systemName: "shower")
                        }
                    }
                )
            }
        )
        .disabled(isSubmitted)
        .task(id: isSubmitted) {
            if isSubmitted {
                await startPairing()
                isSubmitted = false
            }
        
        }
    }
    
    func startPairing() async {
        await tools.alertOnError {
            try await tools.deviceService.pair(scanResult.id)
        }
    }
}

#Preview {
    Preview {
        PairDeviceButton(
            scanResult: PreviewData.data.scanResult
        )
    }
}
