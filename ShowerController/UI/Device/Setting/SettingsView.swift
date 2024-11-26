//
//  SettingsView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    private static let logger = LoggerFactory.logger(SettingsView.self)
    
    @Environment(Toolbox.self) private var tools

    var device: Device
    
    @State private var selectedOutlet: Outlet? = nil
    @State private var editingControllerSettings = false
    @State private var editingWirelessRemoteButtonSettings = false
    
    @State private var isShowingConfirmation =  false
    @State private var confirmationAction: (() -> Void)?
    @State private var isSubmitted =  false

    var body: some View {
        List {
            Section("Outlets") {
                ForEach(device.outlets.sorted(by: \.outletSlot)) { outlet in
                    OutletSettingsListItemView(
                        action: { selectedOutlet = outlet },
                        outlet: outlet
                    )
                }
            }
            Section("Controller") {
                ControllerSettingsListItemView(
                    action: { editingControllerSettings = true },
                    device: device
                )
            }
            Section("Remote Button") {
                WirelessRemoteButtonSettingsListItemView(
                    action: { editingWirelessRemoteButtonSettings = true },
                    device: device
                )
            }
            
            Section("Device") {
                Button("Restart Device") { triggerAction(restartDevice) }
                Button("Factory Reset") { triggerAction(factoryReset) }
            }
        }
        .sheet(item: $selectedOutlet) { outlet in
            EditOutletSettingsView(device: device, outlet: outlet)
        }
        .sheet(isPresented: $editingControllerSettings) {
            EditControllerSettingsView(device: device)
        }
        .sheet(
            isPresented: $editingWirelessRemoteButtonSettings) {
            EditWirelessRemoteButtonSettingsView(device: device)
        }
        .navigationTitle("Settings")
        .deviceStatePolling(device.id)
        .suspendable(
            asyncJobExecutor: tools.asyncJobExecutor,
            onResume: refresh
        )
        .refreshable(action: refresh)
        .task(refresh)
    }
    
    func refresh() async {
        await tools.alertOnError {
            try await tools.deviceService.requestOutletSettings(device.id)
            try await tools.deviceService.requestSettings(device.id)
        }
    }
    
    func triggerAction(_ action: @escaping () -> Void) {
        if !device.isStopped {
            confirmationAction = action
            isShowingConfirmation = true
        } else {
            action()
        }
    }
    
    func actionConfirmed() {
        confirmationAction?()
        confirmationAction = nil
    }
    

    func restartDevice() {
        isSubmitted = true
        tools.submitJobWithErrorHandler {
            try await tools.deviceService.restartDevice(device.id)
        } finally: {
            isSubmitted = false
        }
    }
    
    func factoryReset() {
        isSubmitted = true
        tools.submitJobWithErrorHandler {
            try await tools.deviceService.factoryReset(device.id)
        } finally: {
            isSubmitted = false
        }
    }
}

#Preview {
    Preview {
        SettingsView(
            device: PreviewData.data.device
        )
    }
}
