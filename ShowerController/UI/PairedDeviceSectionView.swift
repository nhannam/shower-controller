//
//  PairedDeviceSectionView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI
import SwiftData

struct PairedDeviceSectionView: View {
    private static let logger = LoggerFactory.logger(PairedDeviceSectionView.self)

    @Environment(Toolbox.self) private var tools

    @Query var devices: [Device]

    @State var isSubmitted = false

    var body: some View {
        Section(
            content: {
                ForEach(devices) { device in
                    NavigationLink(value: PairedDeviceRoute(device: device)) {
                        Label(device.displayName, systemImage: "shower")
                    }
                    .swipeActions(allowsFullSwipe: false) {
                        Button(
                            "Unpair",
                            action: { unpair(device: device) }
                        )
                        .tint(.red)
                    }
                }
            },
            header: { Text("Paired") }
        )
        .disabled(isSubmitted)
    }
    
    func unpair(device: Device) {
        isSubmitted = true
        tools.submitJobWithErrorHandler {
            try await tools.deviceService.unpair(device.id, clientSlot: device.clientSlot)
        } finally: {
            isSubmitted = false
        }
    }
}

#Preview {
    Preview {
        PairedDeviceSectionView()
    }
}
