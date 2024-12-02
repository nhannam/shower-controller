//
//  EditPairedClientView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI

struct EditPairedClientView: View {
    private static let logger = LoggerFactory.logger(EditPresetView.self)
    
    @Environment(\.dismiss) private var dismiss
    @Environment(Toolbox.self) private var tools

    var device: Device
    var pairedClient: PairedClient

    @State private var errorHandler = ErrorHandler()
    @State private var isShowingConfirmation =  false
    @State private var isSubmitted =  false

    var body: some View {
        NavigationStack {
            Form {
                Text(pairedClient.name)
                
                Section {
                    Button("Unpair", role: .destructive) {
                        if device.isStopped {
                            isSubmitted = true
                        } else {
                            isShowingConfirmation = true
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .deviceLockoutConfirmationDialog(
                $isShowingConfirmation,
                device: device,
                confirmAction: { isSubmitted = true }
            )
            .operationInProgress(isSubmitted)
            .alertingErrorHandler(errorHandler)
            .navigationTitle("Paired Client")
            .navigationBarBackButtonHidden()
            .task(id: isSubmitted) {
                if isSubmitted {
                    await unpair()
                    isSubmitted = false
                }
            }
        }
    }
    
    func unpair() async {
        await errorHandler.handleError {
            let isCurrentClient = device.clientSlot == pairedClient.clientSlot

            try await tools.deviceService.unpair(device.id, clientSlot: pairedClient.clientSlot)
            dismiss()
            
            if isCurrentClient {
                tools.navigateHome()
            }
        }
    }
}

#Preview {
    Preview {
        return EditPairedClientView(
            device: PreviewData.data.device,
            pairedClient: PreviewData.data.device.pairedClients[0]
        )
    }
}
