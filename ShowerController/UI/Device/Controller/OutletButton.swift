//
//  OutletWithPresetsButton.swift
//  ShowerController
//
//  Created by Nigel Hannam on 15/11/2024.
//

import SwiftUI
import SwiftData

struct OutletButton: View {
    @Environment(Toolbox.self) private var tools

    var device: Device
    var outlet: Outlet
    
    @State private var isShowingPresetSelector = false
    @State private var isSubmitted = false

    var presets: [Preset] {
        device.presets
            .filter({ $0.outlet.outletSlot == outlet.outletSlot })
            .sorted(by: { $0.presetSlot < $1.presetSlot })
    }

    var body: some View {
        Button(
            action: toggleOutlet,
            label: {
                OutletTypeImage(
                    type: outlet.type,
                    isActive: outlet.isRunning,
                    resizable: true
                )
                .scaledToFit()
                .onLongPressGesture(perform: { isShowingPresetSelector = !presets.isEmpty })
            }
        )
        .disabled(isSubmitted || (!outlet.isRunning && device.defaultPresetSlot == nil))
        .buttonStyle(.borderless)
        .confirmationDialog("Start Preset", isPresented: $isShowingPresetSelector, titleVisibility: .visible) {
            ForEach(presets) { preset in
                Button(
                    action: { startPreset(preset.presetSlot) },
                    label: { Text(preset.name) }
                )
            }
        }
    }
    
    func toggleOutlet() {
        isSubmitted = true
        tools.submitJobWithErrorHandler {
            if outlet.isRunning {
                try await tools.deviceService.stopOutlets(device.id)
            } else {
                let defaultPreset = device.defaultPreset
                if (defaultPreset?.outlet.outletSlot == outlet.outletSlot) {
                    try await tools.deviceService.startPreset(
                        device.id,
                        presetSlot: defaultPreset!.presetSlot
                    )
                } else {
                    try await tools.deviceService.startOutlet(
                        device.id,
                        outletSlot: outlet.outletSlot
                    )
                }
            }
        } finally: {
            isSubmitted = false
        }
    }

    func startPreset(_ presetSlot: UInt8) {
        isSubmitted = true
        tools.submitJobWithErrorHandler {
            try await tools.deviceService.startPreset(device.id, presetSlot: presetSlot)
        } finally: {
            isSubmitted = false
        }
    }
}

#Preview {
    Preview {
        return OutletButton(
            device: PreviewData.data.device,
            outlet: PreviewData.data.device.outlets[1]
        )
    }
}
