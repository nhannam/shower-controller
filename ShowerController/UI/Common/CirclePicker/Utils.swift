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
    var rangeSize: Double {
        upperBound - lowerBound
    }

    func valueToFraction(_ value: Double) -> Double {
        ((value - lowerBound) / rangeSize).clampToRange(range: 0...1)
    }
    
    func fractionToValue(_ fraction: Double) -> Double {
        return ((fraction * rangeSize) + lowerBound).clampToRange(range: self)
    }
}

