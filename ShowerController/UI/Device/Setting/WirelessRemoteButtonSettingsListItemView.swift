//
//  WirelessRemoteButtonSettingsListItemView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI

struct WirelessRemoteButtonSettingsListItemView: View {
    var action: () -> Void
    var device: Device
    
    func outletEnabledLabel(outlet: Outlet) -> some View {
        return OutletTypeLabel(type: outlet.type, isActive: outlet.isEnabledForWirelessRemoteButton)
    }
    
    var body: some View {
        Button(
            action: action,
            label: {
                Label(
                    title: {
                        VStack(alignment: .leading) {
                            ForEach(device.outletsSortedBySlot) { outlet in
                                outletEnabledLabel(outlet: outlet)
                            }
                        }
                    },
                    icon: { Image(systemName: "button.vertical.left.press") }
                )
            }
        )
        .tint(.secondary)
    }
}

#Preview {
    Preview {
        WirelessRemoteButtonSettingsListItemView(
            action: {},
            device: PreviewData.data.device
        )
    }
}
