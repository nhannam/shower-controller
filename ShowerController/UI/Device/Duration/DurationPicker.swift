//
//  DurationPicker.swift
//  ShowerController
//
//  Created by Nigel Hannam on 31/10/2024.
//

import SwiftUI

struct DurationPicker: View {
    static private let SECONDS_PER_MINUTE = 60
    
    var labelText: String
    @Binding var seconds: Int
    
    var maximumSeconds: Int
    
    private let minutesGranularity: Int = 1
    private let secondsGranularity: Int = Device.durationSecondsSelectionSteps
    
    @State private var selectedMinutes: Int = 0
    @State private var selectedSeconds: Int = 0
    
    var body: some View {
        VStack {
            Label(labelText, systemImage: "clock")
            HStack(spacing: 0) {
                Picker("Minutes", selection: $selectedMinutes) {
                    ForEach(Array(stride(from: 0, to: (maximumSeconds / DurationPicker.SECONDS_PER_MINUTE) + minutesGranularity, by: minutesGranularity)), id: \.self) { minute in
                        Text(String(format: "%02d", minute)).tag(minute)
                    }
                }
                
                Text(":")

                Picker("Seconds", selection: $selectedSeconds) {
                    ForEach(Array(stride(from: 0, to: DurationPicker.SECONDS_PER_MINUTE, by: secondsGranularity)), id: \.self) { second in
                        Text(String(format: "%02d", second)).tag(second)
                    }
                }
                .disabled(selectedMinutes == (maximumSeconds / DurationPicker.SECONDS_PER_MINUTE))
            }
            .pickerStyle(.wheel)
        }
        .task {
            updateSelected()
        }
        .onChange(of: selectedMinutes, updateCurrent)
        .onChange(of: selectedSeconds, updateCurrent)
        .onChange(of: seconds, updateSelected)
    }
    
    func updateCurrent() {
        seconds = min(maximumSeconds, selectedMinutes * DurationPicker.SECONDS_PER_MINUTE + selectedSeconds)
    }
    
    func updateSelected() {
        selectedMinutes = seconds / DurationPicker.SECONDS_PER_MINUTE
        selectedSeconds = seconds % DurationPicker.SECONDS_PER_MINUTE
    }
}

#Preview {
    @Previewable @State var seconds = 100
    DurationPicker(
        labelText: "Duration",
        seconds: $seconds,
        maximumSeconds: Device.maximumPermittedDurationSeconds
    )
}
