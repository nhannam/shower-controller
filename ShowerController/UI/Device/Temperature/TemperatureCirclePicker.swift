//
//  TemperatureCirclePicker.swift
//  ShowerController
//
//  Created by Nigel Hannam on 31/10/2024.
//

import SwiftUI

struct TemperatureCirclePicker: View {
    enum LabelPosition { case centre, bottom }
    
    @Environment(\.isEnabled) private var isEnabled
    
    @Binding var temperature: Double
    
    var permittedRange: ClosedRange<Double>
    
    var labelPosition: LabelPosition = .centre

    var onEditingChanged: (Bool) -> Void = { _ in }

    var body: some View {
        GeometryReader { geometry in
            let offsetY: Double = switch labelPosition {
            case .centre:
                0
            case .bottom:
                (geometry.size.width / 2) - 20.0
            }
            
            @State var handle = CirclePickerHandleConfig(
                value: $temperature,
                valueRange: permittedRange,
                step: TemperaturePickerCommon.temperatureSteps,
                onEditingChanged: onEditingChanged
            )
            ZStack {
                CirclePicker(
                    track: TemperaturePickerCommon.trackConfig(
                        isEnabled: isEnabled,
                        padding: 15
                    ),
                    handles: [ handle ]
                )
                
                TemperatureText(temperature: handle.value)
                    .font(.largeTitle)
                    .offset(y: offsetY)
            }
        }
    }
}

#Preview {
    @Previewable @State var temperature = 32.0
    @Previewable @State var labelValue = 32.0
    VStack {
        TemperatureCirclePicker(
            temperature: $temperature,
            permittedRange: 30...48,
            labelPosition: .bottom,
            onEditingChanged: { editing in if (!editing) { labelValue = temperature } }
        )
        Text(String(describing: labelValue))
    }
}
