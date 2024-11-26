//
//  CirclePicker.swift
//  ShowerController
//
//  Created by Nigel Hannam on 31/10/2024.
//

import SwiftUI

struct CirclePicker<TrackShape: ShapeStyle>: View {
    var track: CirclePickerTrackConfig<TrackShape>
    var handles: [CirclePickerHandleConfig]

    func valueToRadians(handle: CirclePickerHandleConfig) -> Double {
        let valueFraction = handle.valueToFraction()
        return track.fractionToRadians(valueFraction)
    }
    
    func positionToValue(_ position: CGPoint, handle: CirclePickerHandleConfig) -> Double {
        let fraction = track.positionToFraction(position)
        return handle.fractionToValue(fraction)
    }

    func drag(handle: CirclePickerHandleConfig) -> some Gesture {
        DragGesture()
            .onChanged { dragValue in
                if (!handle.isEditing) {
                    handle.isEditing = true
                    handle.onEditingChanged(true)
                }
                handle.value = positionToValue(dragValue.location, handle: handle)
            }
            .onEnded { dragValue in
                handle.value = positionToValue(dragValue.location, handle: handle)
                handle.isEditing = false
                handle.onEditingChanged(false)
            }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(
                geometry.size.width,
                geometry.size.height
            )
            let trackRadius = (size / 2) - track.padding
            
            ZStack {
                CirclePickerTrack(track: track)
                    .padding(track.padding)
                
                ForEach(Array(handles.enumerated()), id: \.offset) { offset, handle in
                    handle.view()
                        .offset(x: trackRadius)
                        .rotationEffect(.radians(valueToRadians(handle: handle)))
                        .gesture(drag(handle: handle))
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var value = 32.0
    @Previewable @State var labelValue = 32.0
    @Previewable @State var secondValue = 35.0
    @Previewable @State var secondLabelValue = 32.0
    VStack {
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
                    onEditingChanged: { editing in if (!editing) { labelValue = value } }
                ),
                CirclePickerHandleConfig(
                    value: $secondValue,
                    valueRange: 30...48,
                    onEditingChanged: { editing in if (!editing) { secondLabelValue = secondValue } }
                )
            ]
        )
        Text(String(describing: labelValue))
        Text(String(describing: secondLabelValue))
    }
}
