//
//  OutletSettingsListItemView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI

struct OutletSettingsListItemView: View {
    var action: () -> Void
    var outlet: Outlet
    
    var body: some View {
        Button(
            action: action,
            label: {
                Label(
                    title: {
                        VStack(alignment: .leading) {
                            Text(outlet.type.description)
                            HStack {
                                TemperatureLabel(temperature: outlet.minimumTemperature)
                                Text("Min")
                                TemperatureLabel(temperature: outlet.maximumTemperature)
                                Text("Max")
                            }
                            HStack {
                                DurationLabel(seconds: outlet.maximumDurationSeconds)
                                Text("Max")
                            }
                        }
                    },
                    icon: { OutletTypeImage(type: outlet.type, isActive: outlet.isRunning) }
                )
            }
        )
        .tint(.secondary)
    }
}

#Preview {
    Preview {
        OutletSettingsListItemView(
            action: {},
            outlet: PreviewData.data.device.outletsSortedBySlot[0]
        )
    }
}
