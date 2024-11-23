//
//  PresetsView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI
import SwiftData

struct PresetsView: View {
    private static let logger = LoggerFactory.logger(PresetsView.self)

    @Environment(Toolbox.self) private var tools

    var device: Device
    
    @State private var selected: Preset?
    @State private var isEditing = false

    var body: some View {
        List {
            ForEach(device.presets.sorted(by: { $0.presetSlot < $1.presetSlot })) { preset in
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
        .suspendable(
            asyncJobs: tools.asyncJobs,
            onResume: refresh
        )
        .refreshable(action: refresh)
        .task(refresh)
    }
    
    func refresh() async {
        await tools.alertOnError {
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
