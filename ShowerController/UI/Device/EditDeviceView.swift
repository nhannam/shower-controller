//
//  EditDeviceView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI

struct EditDeviceView: View {
    private static let logger = LoggerFactory.logger(EditDeviceView.self)

    @Environment(\.dismiss) private var dismiss
    @Environment(Toolbox.self) private var tools

    var device: Device
    
    @State private var nickname: String = ""
    
    @State private var isShowingConfirmation =  false
    @State private var isSubmitted =  false

    private var isNicknameValid: Bool {
        return nickname.wholeMatch(of: /.{1, 16}/) != nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                ValidatingView(
                    validatingField: { TextField("Nickname", text: $nickname) },
                    validationText: "1-16 characters",
                    isValid: isNicknameValid
                )
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if !device.isStopped {
                            isShowingConfirmation = true
                        } else {
                            persist()
                        }
                    }.disabled(!isNicknameValid)
                }
            }
            .deviceLockoutConfirmationDialog(
                $isShowingConfirmation,
                device: device,
                confirmAction: persist
            )
            .operationInProgress(isSubmitted)
        }
        .task {
            nickname = device.nickname ?? ""
        }
    }
    
    func persist() {
        isSubmitted = true
        tools.submitJobWithErrorHandler {
            try await tools.deviceService.updateNickname(device.id, nickname: nickname)
            dismiss()
        } finally: {
            isSubmitted = false
        }
    }
}

#Preview {
    Preview {
        EditDeviceView(
            device: PreviewData.data.device
        )
    }
}
