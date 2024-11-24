//
//  ClampToRange.swift
//  ShowerController
//
//  Created by Nigel Hannam on 24/11/2024.
//

import SwiftUI

extension Double {
    func clampToRange(range: ClosedRange<Double>) -> Self {
        return min(range.upperBound, max(range.lowerBound, self))
    }
}
