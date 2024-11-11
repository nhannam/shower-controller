//
//  CirclePickerTrack.swift
//  ShowerController
//
//  Created by Nigel Hannam on 14/11/2024.
//

import SwiftUI

struct CirclePickerTrack<TrackShape: ShapeStyle>: View {
    @MainActor
    struct Config {
        let radius: Double
        let lineWidth: Double
        let radianRange: ClosedRange<Double>
        let radianOffset: Double = halfPi
        let shapeStyle: TrackShape
        var diameter: Double { radius * 2 }
        
        func addOffset(_ trackRadians: Double) -> Double {
            return (trackRadians + radianOffset).truncatingRemainder(dividingBy: twoPi)
        }
        
        func removeOffset(_ radians: Double) -> Double {
            let adjustedRadians = radians < radianOffset ? radians + twoPi : radians
            return adjustedRadians - radianOffset
        }
    }
    
    let config: Config

    var body: some View {
        Circle()
            .trim(
                from: config.radianRange.lowerBound / twoPi,
                to: config.radianRange.upperBound / twoPi
            )
            .rotation(.radians(config.radianOffset))
            .stroke<TrackShape>(
                config.shapeStyle,
                style: StrokeStyle(
                    lineWidth: config.lineWidth,
                    lineCap: .round
                )
            )
            .frame(width: config.diameter, height: config.diameter)
    }
}

#Preview {
    CirclePickerTrack(
        config: CirclePickerTrack.Config(
            radius: 150,
            lineWidth: 10,
            radianRange: 0...twoPi,
            shapeStyle: .green
        )
    )
}
