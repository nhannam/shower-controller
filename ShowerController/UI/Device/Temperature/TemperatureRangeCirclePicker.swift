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
    @Binding var upperTemperature: Double

    var permittedRange: ClosedRange<Double>
    
    var body: some View {
        GeometryReader { geometry in
            let lowerTemperatureSelectableRange = permittedRange.lowerBound...upperTemperature
            let upperTemperatureSelectableRange = lowerTemperature...permittedRange.upperBound

            @State var lowerTemperatureHandle = CirclePickerHandleConfig(
                value: $lowerTemperature,
                valueRange: permittedRange,
                step: TemperaturePickerCommon.temperatureSteps,
                selectableRange: lowerTemperatureSelectableRange,
                view: {
                    AnyView(
                        Capsule()
                            .stroke(.black, lineWidth: 2)
                            .fill(.white)
                            .frame(
                                width: 40,
                                height: 20
                            )
                            .offset(y: -10)
                    )
                }
            )
            @State var upperTemperatureHandle = CirclePickerHandleConfig(
                value: $upperTemperature,
                valueRange: permittedRange,
                step: TemperaturePickerCommon.temperatureSteps,
                selectableRange: upperTemperatureSelectableRange,
                view: {
                    AnyView(
                        Capsule()
                            .stroke(.black, lineWidth: 2)
                            .fill(.white)
                            .frame(
                                width: 40,
                                height: 20
                            )
                            .offset(y: 10)
                    )
                }
            )
            ZStack {
                CirclePicker(
                    track: TemperaturePickerCommon.trackConfig(
                        isEnabled: isEnabled,
                        padding: 20
                    ),
                    handles: [ lowerTemperatureHandle, upperTemperatureHandle ]
                )
                
                VStack {
                    TemperatureText(temperature: lowerTemperatureHandle.value)
                        .font(.largeTitle)
                    TemperatureText(temperature: upperTemperatureHandle.value)
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
