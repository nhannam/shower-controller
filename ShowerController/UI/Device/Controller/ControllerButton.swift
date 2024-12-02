//
//  ControllerButton.swift
//  ShowerController
//
//  Created by Nigel Hannam on 15/11/2024.
//

import SwiftUI
import SwiftData

struct ControllerButton: View {
    enum Action: Equatable { case toggleOutlet, startPreset(_ presetSlot: UInt8) }
    
    @Environment(Toolbox.self) private var tools

    var device: Device
    var userInterfaceButton: UserInterfaceButton
    
    @State private var isShowingPresetSelector = false
    @State private var action: Action? = nil

    var outlet: Outlet {
        userInterfaceButton.outlet
    }
    
    var presets: [Preset] {
        device.presets
            .filter({ $0.outlet.outletSlot == outlet.outletSlot })
            .sorted(by: \.presetSlot)
    }

    var body: some View {
        Button(
            action: { action = .toggleOutlet },
            label: {
                ControllerButtonImage(
                    userInterfaceButton: userInterfaceButton,
                    isActive: outlet.isRunning,
                    resizable: true
                )
                .scaledToFit()
                .onLongPressGesture(perform: { isShowingPresetSelector = true })
            }
        )
        .disabled(action != nil || (!outlet.isRunning && device.defaultPresetSlot == nil))
        .buttonStyle(.borderless)
        .confirmationDialog(presets.isEmpty ? "No Presets For Outlet" : "Start Preset", isPresented: $isShowingPresetSelector, titleVisibility: .visible) {
            ForEach(presets) { preset in
                Button(
                    action: { action = .startPreset(preset.presetSlot) },
                    label: { Text(preset.name) }
                )
            }
        }
        .task(id: action) {
            if let action {
                switch action {
                case .toggleOutlet:
                    await toggleOutlet()
                    
                case .startPreset(let presetSlot):
                    await startPreset(presetSlot)
                }

                self.action = nil
            }
        }
    }
    
    func toggleOutlet() async {
        await tools.alertOnError {
            if outlet.isRunning {
                try await tools.deviceService.pauseOutlets(device.id)
            } else {
                switch userInterfaceButton.start {
                case .outlet:
                    try await tools.deviceService.startOutlet(
                        device.id,
                        outletSlot: outlet.outletSlot
                    )
                    
                case .preset:
                    if let defaultPreset = device.defaultPreset {
                        try await tools.deviceService.startPreset(
                            device.id,
                            presetSlot: defaultPreset.presetSlot
                        )
                    }
                }
            }
        }
    }

    func startPreset(_ presetSlot: UInt8) async {
        await tools.alertOnError {
            try await tools.deviceService.startPreset(device.id, presetSlot: presetSlot)
        }
    }
}

#Preview {
    Preview {
        return ControllerButton(
            device: PreviewData.data.device,
            userInterfaceButton: PreviewData.data.device.userInterface!
                .buttons
                .first(where: { $0.buttonSlot == UserInterfaceButton.buttonSlot1 })!
        )
    }
}
