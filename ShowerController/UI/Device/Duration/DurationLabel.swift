//
//  DurationLabel.swift
//  ShowerController
//
//  Created by Nigel Hannam on 31/10/2024.
//

import SwiftUI

struct DurationLabel: View {
    var seconds: Int
    
    var body: some View {
        Label(
            title: { DurationText(seconds: seconds) },
            icon: { Image(systemName: "clock") }
        )
    }
}

#Preview {
    DurationLabel(
        seconds: 100
    )
}
