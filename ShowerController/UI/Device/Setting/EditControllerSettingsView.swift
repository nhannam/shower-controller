//
//  EditControllerSettingsView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI

struct EditControllerSettingsView: View {
    private static let logger = LoggerFactory.logger(EditControllerSettingsView.self)

    @Environment(\.dismiss) private var dismiss
    @Environment(Toolbox.self) private var tools

    var device: Device

    @State private var standbyLightingEnabled = true
    @State private var outletsSwitched: Bool = false
    
    @State private var errorHandler = ErrorHandler()
    @State private var isShowingConfirmation =  false
    @State private var isSubmitted =  false

    var body: some View {
        NavigationStack {
            Form {
                Toggle("Standby Lighting", systemImage: "lightbulb", isOn: $standbyLightingEnabled)
                Toggle("Outlets Switched", systemImage: "shuffle.circle", isOn: $outletsSwitched)
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
            .alertingErrorHandler(errorHandler)
            .navigationTitle("Controller")
            .navigationBarBackButtonHidden()
            .task {
                standbyLightingEnabled = device.standbyLightingEnabled
                outletsSwitched = device.outletsSwitched
            }
            .task(id: isSubmitted) {
                if isSubmitted {
                    await persist()
                    isSubmitted = false
                }
            }
        }
    }
    
    func persist() async {
        await errorHandler.handleError {
            try await tools.deviceService.updateControllerSettings(
                device.id,
                standbyLightingEnabled: standbyLightingEnabled,
                outletsSwitched: outletsSwitched
            )
            dismiss()
        }
    }
}

#Preview {
    Preview {
        EditControllerSettingsView(
            device: PreviewData.data.device
        )
    }
}
