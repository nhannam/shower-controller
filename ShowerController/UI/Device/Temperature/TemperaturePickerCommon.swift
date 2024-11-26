//
//  TemperaturePickerCommon.swift
//  ShowerController
//
//  Created by Nigel Hannam on 26/11/2024.
//

import SwiftUI

struct TemperaturePickerCommon {
    static let trimCircle = twoPi * 0.12
    static let temperatureSteps = 1.0

    static func trackConfig(isEnabled: Bool, padding: Double) -> CirclePickerTrackConfig<LinearGradient> {
        CirclePickerTrackConfig(
            radianRange: Self.trimCircle...twoPi-Self.trimCircle,
            lineWidth: 10,
            shapeStyle: LinearGradient(
                gradient: Gradient(colors: isEnabled ? [.blue, .red] : [ .secondary ]),
                startPoint: .leading,
                endPoint: .trailing
            ),
            padding: padding
       )
    }
}
