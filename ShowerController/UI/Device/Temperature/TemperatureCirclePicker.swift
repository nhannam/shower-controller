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
    @State private var temperaturePendingValue: Double?

    var secondaryTemperature: Double? = nil

    var temperatureRange: ClosedRange<Double>
    
    var labelPosition: LabelPosition = .centre

    var body: some View {
        GeometryReader { geometry in
            let offsetY: Double = switch labelPosition {
            case .centre:
                0
            case .bottom:
                (geometry.size.width / 2) - 20.0
            }
            let trimCircle = twoPi * 0.12
            let trackColours: [Color] = isEnabled ? [.blue, .red] : [ .secondary ]
            
            
            @State var handle = CirclePickerHandleConfig(
                value: $temperature,
                valueRange: temperatureRange,
                step: 1,
                height: 30,
                width: 30,
                lineWidth: 2,
                updateValueWhileDragging: false,
                pendingValue: $temperaturePendingValue
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
                    handles: [ handle ]
                )
                
                TemperatureText(temperature: handle.handleValue)
                    .font(.largeTitle)
                    .offset(y: offsetY)
            }
        }
    }
}

#Preview {
    @Previewable @State var temperature = 32.0
    TemperatureCirclePicker(
        temperature: $temperature,
        temperatureRange: 30...48,
        labelPosition: .bottom
    )
}
