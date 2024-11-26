//
//  TemperaturePicker2.swift
//  ShowerController
//
//  Created by Nigel Hannam on 31/10/2024.
//

import SwiftUI

struct CirclePicker<TrackShape: ShapeStyle>: View {
    var track: CirclePickerTrackConfig<TrackShape>
    var handles: [CirclePickerHandleConfig]

    func valueToRadians(_ value: Double, handle: CirclePickerHandleConfig) -> Double {
        let valueFraction = handle.valueToFraction(value)
        return track.fractionToRadians(valueFraction)
    }
    
    func positionToValue(_ position: CGPoint, handle: CirclePickerHandleConfig) -> Double {
        let fraction = track.positionToFraction(position)
        return handle.fractionToValue(fraction)
    }

    func drag(handle: CirclePickerHandleConfig) -> some Gesture {
        DragGesture()
            .onChanged { dragValue in
                let newValue = positionToValue(dragValue.location, handle: handle)
                if (handle.updateValueWhileDragging) {
                    handle.value = newValue
                } else {
                    handle.pendingValue = newValue
                }
            }
            .onEnded { dragValue in
                handle.value = positionToValue(dragValue.location, handle: handle)
                handle.pendingValue = nil
            }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(
                geometry.size.width,
                geometry.size.height
            )
            let trackDiameter = size - (handles.compactMap(\.width).max() ?? 0.0)
            let trackRadius = trackDiameter / 2
            
            ZStack {
                CirclePickerTrack(track: track)
                    .frame(width: trackDiameter, height: trackDiameter)
                
                ForEach(Array(handles.enumerated()), id: \.offset) { offset, handle in
                    CirclePickerHandleView(handle: handle)
                        .offset(x: trackRadius)
                        .rotationEffect(.radians(valueToRadians(handle.handleValue, handle: handle)))
                        .gesture(drag(handle: handle))
                }
            }
            .frame(
                width: size,
                height: size
            )
        }
    }
}

#Preview {
    @Previewable @State var value = 32.0
    @Previewable @State var pendingValue: Double? = nil
    @Previewable @State var secondValue = 35.0
    @Previewable @State var pendingSecondValue: Double? = nil
    CirclePicker(
        track: CirclePickerTrackConfig(
            radianRange: .pi/4...((7 * .pi)/4),
            lineWidth: 10,
            shapeStyle: .orange
        ),
        handles: [
            CirclePickerHandleConfig(
                value: $value,
                valueRange: 30...48,
                height: 10,
                width: 40,
                lineWidth: 2,
                updateValueWhileDragging: false,
                pendingValue: $pendingValue
            ),
            CirclePickerHandleConfig(
                value: $secondValue,
                valueRange: 30...48,
                height: 30,
                width: 30,
                lineWidth: 2,
                updateValueWhileDragging: true,
                pendingValue: $pendingSecondValue
            )
        ]
    )
}
