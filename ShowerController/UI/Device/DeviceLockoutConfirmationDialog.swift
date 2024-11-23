//
//  DeviceLockoutConfirmationDialog.swift
//  ShowerController
//
//  Created by Nigel Hannam on 11/11/2024.
//

import SwiftUI

struct DeviceLockoutConfirmationDialog: ViewModifier {
    private static let logger = LoggerFactory.logger(DeviceLockoutConfirmationDialog.self)
    
    @Binding var isShowing: Bool
    var device: Device
    var confirmAction: @MainActor () -> Void
    
    func body(content: Content) -> some View {
        var warningText: String {
            switch device.timerState {
            case .running:
                "Water flow will be stopped and there will be a 5 second delay before the operation completes"
            case .paused:
                "There will be a 5 second delay before the operation completes"
            default:
                "Proceed?"
            }
        }

        content
            .confirmationDialog(
                "Confirm",
                isPresented: $isShowing,
                actions: {
                    Button("Confirm", action: confirmAction)
                },
                message: { Text(warningText) }
            )
            .dialogIcon(
                Image(systemName: "exclamationmark.triangle")
            )
    }
}


extension View {
    func deviceLockoutConfirmationDialog(
        _ isShowing: Binding<Bool>,
        device: Device,
        confirmAction: @escaping @MainActor () -> Void
    ) -> some View {
        modifier(
            DeviceLockoutConfirmationDialog(isShowing: isShowing, device: device, confirmAction: confirmAction)
        )
    }
}
