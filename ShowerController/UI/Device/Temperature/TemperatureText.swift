//
//  TemperatureText.swift
//  ShowerController
//
//  Created by Nigel Hannam on 14/11/2024.
//

import SwiftUI

struct TemperatureText: View {
    var temperature: Double

    private let temperatureStyle: Measurement<UnitTemperature>.FormatStyle =
        .measurement(
            numberFormatStyle: .number.precision(.fractionLength(0...1))
        )


    var body: some View {
        Text(Measurement(value: temperature, unit: .celsius), format: temperatureStyle)
    }
}

#Preview {
    TemperatureText(temperature: 48)
}
