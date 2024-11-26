//
//  CirclePickerConfig.swift
//  ShowerController
//
//  Created by Nigel Hannam on 26/11/2024.
//

import Foundation
import SwiftUI

struct CirclePickerHandleConfig {
    @Binding var value: Double
    let valueRange: ClosedRange<Double>
    var step: Double?
    
    var selectableRange: ClosedRange<Double>?

    let height: Double
    let width: Double
    let lineWidth: Double
    
    var updateValueWhileDragging = true
    @Binding var pendingValue: Double?
    
    var handleValue: Double {
        pendingValue ?? value
    }
    
    func valueToFraction(_ value: Double) -> Double {
        return valueRange.valueToFraction(value)
    }
    
    func clampValue(_ value: Double) -> Double {
        if let selectableRange {
            return value.clampToRange(range: selectableRange)
        } else {
            return value.clampToRange(range: valueRange)
        }
    }

    func fractionToValue(_ fraction: Double) -> Double {
        var value = valueRange.fractionToValue(fraction)
        
        if let step {
            value = round(value / step) * step
        }
        
        return clampValue(value)
    }
}

struct CirclePickerTrackConfig<TrackShape: ShapeStyle> {
    let radianRange: ClosedRange<Double>
    let radianOffset: Double = halfPi
    let lineWidth: Double
    let shapeStyle: TrackShape

    func fractionToRadians(_ fraction: Double) -> Double {
        let trackValue = radianRange.fractionToValue(fraction)
        return addOffset(trackValue)
    }
    
    func positionToFraction(_ position: CGPoint) -> Double {
        let offSetTrackPosition = atan2(position.y, position.x)
        let radians = removeOffset(offSetTrackPosition)
        return radianRange.valueToFraction(radians)
    }
    
    private func addOffset(_ trackRadians: Double) -> Double {
        return (trackRadians + radianOffset).truncatingRemainder(dividingBy: twoPi)
    }
    
    private func removeOffset(_ radians: Double) -> Double {
        let adjustedRadians = radians < radianOffset ? radians + twoPi : radians
        return adjustedRadians - radianOffset
    }
}

