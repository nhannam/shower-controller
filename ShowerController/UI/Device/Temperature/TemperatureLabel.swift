//
//  TemperatureLabel.swift
//  ShowerController
//
//  Created by Nigel Hannam on 31/10/2024.
//

import SwiftUI

struct TemperatureLabel: View {
    var temperature: Double
    
    var body: some View {
        Label(
            title: {
                TemperatureText(temperature: temperature)
            },
            icon: { Image(systemName: "thermometer")}
        )
    }
}

#Preview {
    TemperatureLabel(
        temperature: 45
    )
}
