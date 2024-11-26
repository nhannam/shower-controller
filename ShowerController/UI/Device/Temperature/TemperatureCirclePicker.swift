//
//  TemperatureCirclePicker.swift
//  ShowerController
//
//  Created by Nigel Hannam on 31/10/2024.
//

import SwiftUI

struct TemperatureCirclePicker: View {
    @Environment(\.isEnabled) private var isEnabled
    
    @Binding var temperature: Double
    
    var permittedRange: ClosedRange<Double>
    
    var onEditingChanged: (Bool) -> Void = { _ in }

    var body: some View {
        @State var handle = CirclePickerHandleConfig(
            value: $temperature,
            valueRange: permittedRange,
            step: TemperaturePickerCommon.temperatureSteps,
            onEditingChanged: onEditingChanged
        )

        CirclePicker(
            track: TemperaturePickerCommon.trackConfig(
                isEnabled: isEnabled,
                padding: 15
            ),
            handles: [ handle ]
        )
    }
}

#Preview {
    @Previewable @State var temperature = 32.0
    @Previewable @State var labelValue = 32.0
    VStack {
        TemperatureCirclePicker(
            temperature: $temperature,
            permittedRange: 30...48,
            onEditingChanged: { editing in if (!editing) { labelValue = temperature } }
        )
        Text(String(describing: labelValue))
    }
}
