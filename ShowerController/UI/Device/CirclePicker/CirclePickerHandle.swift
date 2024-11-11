//
//  CirclePickerHandle.swift
//  ShowerController
//
//  Created by Nigel Hannam on 14/11/2024.
//

import SwiftUI

struct CirclePickerHandle: View {
    struct Config {
        let radius: Double
        let lineWidth: Double
        var diameter: Double { radius * 2 }
    }
    
    let config: Config
    let position: CGSize

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: config.lineWidth)
                .frame(width: config.diameter, height: config.diameter)
                .offset(position)
            
            Circle()
                .foregroundStyle(.white)
                .frame(width: config.diameter, height: config.diameter)
                .offset(position)
        }
    }
}

#Preview {
    CirclePickerHandle(
        config: CirclePickerHandle.Config(
            radius: 14,
            lineWidth: 5
        ),
        position: CGSize(width: 0, height: 0)
    )
}

