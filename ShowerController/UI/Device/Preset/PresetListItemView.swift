//
//  PresetListItemView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI

struct PresetListItemView: View {
    var action: () -> Void
    var preset: Preset
    var isDefault: Bool
    
    var body: some View {
        Button(
            action: action,
            label: {
                Label(
                    title: {
                        VStack(alignment: .leading) {
                            Text(preset.name)
                            HStack {
                                OutletTypeLabel(type: preset.outlet.type)
                                TemperatureLabel(temperature: preset.targetTemperature)
                            }
                            DurationLabel(seconds: preset.durationSeconds)
                        }
                    },
                    icon: { Image(systemName: isDefault ? "checkmark.square" : "square") }
                )
            }
        )
        .tint(.secondary)
    }
}

#Preview {
    Preview {
        PresetListItemView(
            action: {},
            preset: PreviewData.data.device.presets[0],
            isDefault: true
        )
    }
}
