//
//  PresetsView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI

struct PresetsView: View {
    private static let logger = LoggerFactory.logger(PresetsView.self)

    @Environment(Toolbox.self) private var tools

    var device: Device
    
    @State private var selected: Preset?
    @State private var isEditing = false
    @State private var errorHandler = ErrorHandler()

    var body: some View {
        List {
            ForEach(device.presets.sorted(by: \.presetSlot)) { preset in
                var isDefaultPreset: Bool {
                    device.defaultPresetSlot == preset.presetSlot
                }
                
                PresetListItemView(
                    action: {
                        selected = preset
                        isEditing = true
                    },
                    preset: preset,
                    isDefault: isDefaultPreset
                )
            }
        }
        .sheet(isPresented: $isEditing) {
            EditPresetView(device: device, preset: $selected)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add", systemImage: "plus") {
                    selected = nil
                    isEditing = true
                }
            }
        }
        .navigationTitle("Presets")
        .deviceStatePolling(device.id)
        .alertingErrorHandler(errorHandler)
        .suspendable(
            onResume: refresh
        )
        .refreshable(action: refresh)
        .task(refresh)
    }
    
    func refresh() async {
        await errorHandler.handleError {
            try await tools.deviceService.requestOutletSettings(device.id)
            try await tools.deviceService.requestPresets(device.id)
        }
    }    
}

#Preview {
    Preview {
        PresetsView(
            device: PreviewData.data.device
        )
    }
}
