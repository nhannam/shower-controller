//
//  ControllerSettingsListItemView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI

struct ControllerSettingsListItemView: View {
    var action: () -> Void
    var device: Device
    
    var body: some View {
        Button(
            action: action,
            label: {
                Label(
                    title: {
                        VStack(alignment: .leading) {
                            Label("Standby Lighting", systemImage: device.standbyLightingEnabled ? "lightbulb" : "lightbulb.slash")
                            Label("Outlets Switched", systemImage: device.outletsSwitched ? "shuffle.circle.fill" : "shuffle.circle")
                        }
                    },
                    icon: { Image(systemName: "play") }
                )
            }
        )
        .tint(.secondary)
    }
}

#Preview {
    Preview {
        ControllerSettingsListItemView(
            action: {},
            device: PreviewData.data.device
        )
    }
}
