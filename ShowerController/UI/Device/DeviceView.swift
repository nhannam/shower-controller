//
//  DeviceView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI
import SwiftData

struct DeviceView: View {
    private static let logger = LoggerFactory.logger(DeviceView.self)
    
    @Environment(Toolbox.self) private var tools

    @State private var isEditing = false

    var device: Device
    
    var body: some View {
        List {
            Section {
                DeviceControlsView(device: device)
            }
            
            Section {
                NavigationLink(value: PairedDeviceDetailsRoute.presets(device: device)) {
                    Label("Presets", systemImage: "bathtub")
                }
                NavigationLink(value: PairedDeviceDetailsRoute.pairedClients(device: device)) {
                    Label("Clients", systemImage: "ipad.and.iphone")
                }
                NavigationLink(value: PairedDeviceDetailsRoute.settings(device: device)) {
                    Label("Settings", systemImage: "gear")
                }
                NavigationLink(value: PairedDeviceDetailsRoute.technicalInformation(device: device)) {
                    Label("Technical Information", systemImage: "info.circle")
                }
            }

//            Section {
//                Button("Unknown Command") { unknownCommand() }
//            }
        }
        .navigationTitle(device.displayName)
        .navigationDestination(for: PairedDeviceDetailsRoute.self) { route in
            switch route {
            case .presets(let device):
                PresetsView(device: device)
            case .pairedClients(let device):
                PairedClientsView(device: device)
            case .settings(let device):
                SettingsView(device: device)
            case .technicalInformation(let device):
                TechnicalInformationView(device: device)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isEditing = true
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            EditDeviceView(device: device)
        }
        .deviceStatePolling(device.id)
        .suspendable(
            asyncJobs: tools.asyncJobs,
            onResume: refresh
        )
        .refreshable(action: refresh)
        .task(refresh)
    }
    
    func refresh() async {
        await tools.alertOnError {
            try await tools.deviceService.requestDeviceDetails(device.id)
            try await tools.deviceService.requestOutletSettings(device.id)
            try await tools.deviceService.requestPresets(device.id)
        }
    }
    
    func unknownCommand() {
        tools.submitJobWithErrorHandler {
            try await tools.deviceService.unknownCommand(device.id)
        }
    }
}

#Preview {
    Preview {
        DeviceView(
            device: PreviewData.data.device
        )
    }
}
