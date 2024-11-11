//
//  DurationText.swift
//  ShowerController
//
//  Created by Nigel Hannam on 31/10/2024.
//

import SwiftUI

struct DurationText: View {
    var seconds: Int
    
    var body: some View {
        Text(Duration(secondsComponent: Int64(seconds), attosecondsComponent: 0),
             format: .time(pattern: .minuteSecond(padMinuteToLength: 2)))
    }
}

#Preview {
    DurationText(
        seconds: 100
    )
}
