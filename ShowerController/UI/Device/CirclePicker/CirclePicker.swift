//
//  TemperaturePicker2.swift
//  ShowerController
//
//  Created by Nigel Hannam on 31/10/2024.
//

import SwiftUI

struct CirclePicker<TrackShape: ShapeStyle, Label: View>: View {
    @Binding var value: Double
    var valueRange: ClosedRange<Double>
    var step: Double?
    var trackRadianRange: ClosedRange<Double>
    var shapeStyle: TrackShape
    var label: ((_ value: Double, _ pendingValue: Double?) -> Label)?
    var updateValueWhileDragging = true

    @State private var pendingValue: Double?
    
    func valueToPosition(_ value: Double, track: CirclePickerTrack<TrackShape>.Config) -> CGSize {
        let valueFraction = valueRange.valueToFraction(value)
        let trackValue = track.radianRange.fractionToValue(valueFraction)
        let offSetTrackPosition = track.addOffset(trackValue)
        return CGSize(
            width: track.radius * cos(offSetTrackPosition),
            height: track.radius * sin(offSetTrackPosition)
        )
    }
    
    func positionToValue(_ position: CGPoint, track: CirclePickerTrack<TrackShape>.Config) -> Double {
        let offSetTrackPosition = atan2(position.y, position.x)
        let radians = track.removeOffset(offSetTrackPosition)
        
        let trackFraction = track.radianRange.valueToFraction(radians)
        var value = valueRange.fractionToValue(trackFraction)
        
        if let step {
            value = round(value / step) * step
        }
        
        return value
    }
    
    func drag(track: CirclePickerTrack<TrackShape>.Config) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if (updateValueWhileDragging) {
                    self.value = positionToValue(value.location, track: track)
                } else {
                    self.pendingValue = positionToValue(value.location, track: track)
                }
            }
            .onEnded { value in
                self.value = positionToValue(value.location, track: track)
            }
    }
    
    var body: some View {
        var handleValue: Double {
            pendingValue ?? value
        }

        GeometryReader { geometry in
            let size = min(
                geometry.size.width,
                geometry.size.height
            )
            let handle = CirclePickerHandle.Config(
                radius: 15,
                lineWidth: 5
            )
            let track = CirclePickerTrack<TrackShape>.Config(
                radius: (size - handle.diameter) / 2,
                lineWidth: 10,
                radianRange: trackRadianRange,
                shapeStyle: shapeStyle
            )
            
            ZStack {
                CirclePickerTrack(config: track)
                CirclePickerHandle(
                    config: handle,
                    position: valueToPosition(handleValue, track: track)
                )
                .gesture(drag(track: track))
                label?(value, pendingValue)
            }
            .frame(
                width: size,
                height: size
            )
            .onChange(of: value, initial: true) {
                pendingValue = nil
            }
            .task {
                value = value.clampToRange(range: valueRange)
            }
        }
    }
}

#Preview {
    @Previewable @State var value = 32.0
    CirclePicker<Color, Text>(
        value: $value,
        valueRange: 30...48,
        trackRadianRange: .pi/4...((7 * .pi)/4),
        shapeStyle: .orange
    )
}
