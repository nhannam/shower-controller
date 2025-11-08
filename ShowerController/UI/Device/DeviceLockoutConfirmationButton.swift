//
//  ControllerButton.swift
//  ShowerController
//
//  Created by Nigel Hannam on 15/11/2024.
//

import SwiftUI

struct DeviceLockoutConfirmationButton: View {
    @State private var isShowingConfirmation =  false
    
    var title: String
    var systemImage: String
    var device: Device
    var action: @MainActor () -> Void

    init(_ title: String, device: Device, action: @escaping @MainActor () -> Void) {
        self.title = title
        self.systemImage = ""
        self.device = device
        self.action = action
    }

    init(_ title: String, systemImage: String, device: Device, action: @escaping @MainActor () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.device = device
        self.action = action
    }
    
    var body: some View {
        Button(title, systemImage: systemImage, action: onClicked)
            .deviceLockoutConfirmationDialog(
                $isShowingConfirmation,
                device: device,
                confirmAction: action
            )
    }
    
    private func onClicked() {
        if device.isStopped {
            action()
        } else {
            isShowingConfirmation = true
        }
    }
}

#Preview {
    Preview {
        return DeviceLockoutConfirmationButton(
            "Title",
            systemImage: "checkmark",
            device: PreviewData.data.device
        ) { }
    }
}
