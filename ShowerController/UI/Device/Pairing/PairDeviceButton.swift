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

    var device: Device
    
    @State private var isSubmitted = false

    var body: some View {
        Button(
            action: startPairing,
            label: {
                Label(
                    title: { Text(device.name) },
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
    }
    
    func startPairing() {
        isSubmitted = true
        tools.submitJobWithErrorHandler {
            try await tools.deviceService.pair(device.id)
        } finally: {
            isSubmitted = false
        }
    }
}

#Preview {
    Preview {
        PairDeviceButton(
            device: PreviewData.data.unpairedDevice
        )
    }
}
