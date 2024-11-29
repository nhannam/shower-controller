//
//  TemperatureLabel.swift
//  ShowerController
//
//  Created by Nigel Hannam on 31/10/2024.
//

import SwiftUI

struct ControllerButtonImage: View {
    var userInterfaceButton : UserInterfaceButton
    var isActive = false
    var resizable = false

    var body: some View {
        switch userInterfaceButton.display {
        case .power:
            let systemImage = "power.circle" + (isActive ? ".fill" : "")
            if resizable {
                Image(systemName: systemImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: systemImage)
            }
        case .outlet:
            OutletTypeImage(type: userInterfaceButton.outlet.type, isActive: isActive, resizable: resizable)
        }
    }
}

#Preview {
    ControllerButtonImage(
        userInterfaceButton: PreviewData.data.device.userInterface!.buttons.first!,
        isActive: true
    )
}
