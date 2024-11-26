//
//  CirclePickerTrackView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 26/11/2024.
//

import SwiftUI

struct CirclePickerTrack<TrackShape: ShapeStyle>: View {
    var track: CirclePickerTrackConfig<TrackShape>

    var body: some View {
        Circle()
            .trim(
                from: track.radianRange.lowerBound / twoPi,
                to: track.radianRange.upperBound / twoPi
            )
            .rotation(.radians(track.radianOffset))
            .stroke<TrackShape>(
                track.shapeStyle,
                style: StrokeStyle(
                    lineWidth: track.lineWidth,
                    lineCap: .round
                )
            )
    }
}

#Preview {
    Preview {
        CirclePickerTrack(
            track: CirclePickerTrackConfig(
                radianRange: .pi/4...((7 * .pi)/4),
                lineWidth: 10,
                shapeStyle: .orange
            )
        )
    }
}
