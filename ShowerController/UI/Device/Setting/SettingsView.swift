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
    
    enum Action: Equatable { case restart, factoryReset }

    @Environment(Toolbox.self) private var tools

    var device: Device
    
    @State private var selectedOutlet: Outlet? = nil
    @State private var editingControllerSettings = false
    @State private var editingWirelessRemoteButtonSettings = false
    
    @State private var isShowingConfirmation =  false
    @State private var pendingConfirmationAction: Action? = nil
    @State private var action: Action? = nil

    var body: some View {
        List {
            Section("Outlets") {
                ForEach(device.outletsSortedBySlot) { outlet in
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
                Button("Restart Device") { triggerAction(.restart) }
                Button("Factory Reset") { triggerAction(.factoryReset) }
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
        .deviceLockoutConfirmationDialog(
            $isShowingConfirmation,
            device: device,
            confirmAction: actionConfirmed
        )
        .navigationTitle("Settings")
        .deviceStatePolling(device.id)
        .suspendable(
            onResume: refresh
        )
        .refreshable(action: refresh)
        .task(refresh)
        .task(id: action) {
            if let action {
                switch action {
                case .restart:
                    await restartDevice()
                case .factoryReset:
                    await factoryReset()
                }
                self.action = nil
            }
        }
    }
    
    func refresh() async {
        await tools.alertOnError {
            try await tools.deviceService.requestOutletSettings(device.id)
            try await tools.deviceService.requestSettings(device.id)
        }
    }
    
    func triggerAction(_ action: Action) {
        if device.isStopped {
            self.action = action
        } else {
            pendingConfirmationAction = action
            isShowingConfirmation = true
        }
    }
    
    func actionConfirmed() {
        action = pendingConfirmationAction
        pendingConfirmationAction = nil
    }
    

    func restartDevice() async {
        await tools.alertOnError {
            try await tools.deviceService.restartDevice(device.id)
        }
    }
    
    func factoryReset() async {
        await tools.alertOnError {
            try await tools.deviceService.factoryReset(device.id)
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
