//
//  TemperatureRangeCirclePicker.swift
//  ShowerController
//
//  Created by Nigel Hannam on 26/11/2024.
//

import SwiftUI

struct TemperatureRangeCirclePicker: View {
    enum LabelPosition { case centre, bottom }
    
    @Environment(\.isEnabled) private var isEnabled
    
    @Binding var lowerTemperature: Double
    @State private var lowerTemperaturePendingValue: Double?

    @Binding var upperTemperature: Double
    @State private var upperTemperaturePendingValue: Double?

    var permittedRange: ClosedRange<Double>
    
    var body: some View {
        GeometryReader { geometry in
            let trimCircle = twoPi * 0.12
            let trackColours: [Color] = isEnabled ? [.blue, .red] : [ .secondary ]
            let temperatureSteps = 1.0
            let lowerTemperatureSelectableRange = permittedRange.lowerBound...upperTemperature
            let upperTemperatureSelectableRange = lowerTemperature...permittedRange.upperBound

            @State var lowerTemperatureHandle = CirclePickerHandleConfig(
                value: $lowerTemperature,
                valueRange: permittedRange,
                step: temperatureSteps,
                selectableRange: lowerTemperatureSelectableRange,
                height: 30,
                width: 30,
                lineWidth: 2,
                updateValueWhileDragging: false,
                pendingValue: $lowerTemperaturePendingValue
            )
            @State var upperTemperatureHandle = CirclePickerHandleConfig(
                value: $upperTemperature,
                valueRange: permittedRange,
                step: temperatureSteps,
                selectableRange: upperTemperatureSelectableRange,
                height: 30,
                width: 30,
                lineWidth: 2,
                updateValueWhileDragging: false,
                pendingValue: $upperTemperaturePendingValue
            )
            ZStack {
                CirclePicker(
                    track: CirclePickerTrackConfig(
                        radianRange: trimCircle...twoPi-trimCircle,
                        lineWidth: 10,
                        shapeStyle: LinearGradient(
                            gradient: Gradient(colors: trackColours),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    ),
                    handles: [ lowerTemperatureHandle, upperTemperatureHandle ]
                )
                
                VStack {
                    TemperatureText(temperature: lowerTemperatureHandle.handleValue)
                        .font(.largeTitle)
                    TemperatureText(temperature: upperTemperatureHandle.handleValue)
                        .font(.largeTitle)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var lowerTemperature = 32.0
    @Previewable @State var upperTemperature = 35.0
    TemperatureRangeCirclePicker(
        lowerTemperature: $lowerTemperature,
        upperTemperature: $upperTemperature,
        permittedRange: 30...48
    )
}
