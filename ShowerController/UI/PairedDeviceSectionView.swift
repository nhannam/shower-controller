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

    @State var selectedDevice: Device? = nil

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
                            action: { selectedDevice = device }
                        )
                        .tint(.red)
                    }
                }
            },
            header: { Text("Paired") }
        )
        .disabled(selectedDevice != nil)
        .task(id: selectedDevice) {
            if let selectedDevice {
                await unpair(device: selectedDevice)
                self.selectedDevice = nil
            }
        }
    }
    
    func unpair(device: Device) async {
        await tools.alertOnError {
            try await tools.deviceService.unpair(device.id, clientSlot: device.clientSlot)
        }
    }
}

#Preview {
    Preview {
        PairedDeviceSectionView()
    }
}
