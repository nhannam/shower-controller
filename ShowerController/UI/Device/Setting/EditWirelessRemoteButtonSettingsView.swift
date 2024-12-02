//
//  EditWirelessRemoteButtonSettingsView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI

struct EditWirelessRemoteButtonSettingsView: View {
    private static let logger = LoggerFactory.logger(EditControllerSettingsView.self)

    @Environment(\.dismiss) private var dismiss
    @Environment(Toolbox.self) private var tools

    var device: Device

    @State private var outletsEnabled: [Int:Bool] = [:]

    @State private var isShowingConfirmation =  false
    @State private var isSubmitted =  false

    var body: some View {
        NavigationStack {
            Form {
                ForEach(device.outletsSortedBySlot) { outlet in
                    var binding: Binding<Bool> {
                        Binding<Bool>(
                            get: { outletsEnabled[outlet.outletSlot] ?? false },
                            set: { enabled in outletsEnabled[outlet.outletSlot] = enabled }
                        )
                    }
                           
                    Toggle(
                        isOn: binding,
                        label: {
                            OutletTypeLabel(type: outlet.type)
                        }
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if device.isStopped {
                            isSubmitted = true
                        } else {
                            isShowingConfirmation = true
                        }
                    }
                }
            }
            .deviceLockoutConfirmationDialog(
                $isShowingConfirmation,
                device: device,
                confirmAction: { isSubmitted = true }
            )
            .operationInProgress(isSubmitted)
            .navigationTitle("Remote Button")
            .navigationBarBackButtonHidden()
        }
        .task {
            outletsEnabled = device.outletsSortedBySlot.reduce(into: [Int: Bool]()) { dict, outlet in
                dict[outlet.outletSlot] = outlet.isEnabledForWirelessRemoteButton
            }
        }
        .task(id: isSubmitted) {
            if isSubmitted {
                await persist()
                isSubmitted = false
            }
        }
    }
    
    func persist() async {
        await tools.alertOnError {
            let outletSlotsEnabled = outletsEnabled
                .filter({ _, enabled in enabled })
                .map({ outletSlot, _ in outletSlot})
            
            try await tools.deviceService.updateWirelessRemoteButtonSettings(
                device.id,
                wirelessRemoteButtonOutletsEnabled: outletSlotsEnabled
            )
            dismiss()
        }
    }
}

#Preview {
    Preview {
        EditWirelessRemoteButtonSettingsView(
            device: PreviewData.data.device
        )
    }
}
