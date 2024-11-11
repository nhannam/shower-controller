//
//  Utils.swift
//  ShowerController
//
//  Created by Nigel Hannam on 14/11/2024.
//

import Foundation

let twoPi: Double = .pi * 2
let halfPi: Double = .pi / 2

extension ClosedRange where Bound == Double {
    var range: Double {
        upperBound - lowerBound
    }

    func valueToFraction(_ value: Double) -> Double {
        (value - lowerBound) / range
    }
    
    func fractionToValue(_ fraction: Double) -> Double {
        Swift.max(
            Swift.min(
                (fraction * range) + lowerBound,
                upperBound
            ),
            lowerBound
        )
    }
}

