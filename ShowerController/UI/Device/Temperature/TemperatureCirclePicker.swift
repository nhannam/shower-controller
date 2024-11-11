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

            CirclePicker(
                value: $temperature,
                valueRange: temperatureRange,
                step: 1,
                trackRadianRange: trimCircle...twoPi-trimCircle,
                shapeStyle: LinearGradient(
                    gradient: Gradient(colors: trackColours),
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                label: { value, pendingValue in
                    TemperatureText(temperature: pendingValue ?? value)
                        .font(.largeTitle)
                        .offset(y: offsetY)
                },
                updateValueWhileDragging: false
            )
        }
    }
}

#Preview {
    @Previewable @State var value = 32.0
    TemperatureCirclePicker(
        temperature: $value,
        temperatureRange: 30...48,
        labelPosition: .bottom
    )
}
