//
//  EditPresetView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI

struct EditPresetView: View {
    private static let logger = LoggerFactory.logger(EditPresetView.self)
    
    enum Action: Equatable { case deletePreset, persistPreset(makeDefault: Bool) }

    @Environment(\.dismiss) private var dismiss
    @Environment(Toolbox.self) private var tools

    var device: Device
    
    // Unsure why this needs to be a binding, but without it the task
    // seems to run with nil sometimes when it should have a value
    @Binding var preset: Preset?

    @State private var name: String = ""
    @State private var outlet: Outlet? = nil
    @State private var targetTemperature: Double = 0
    @State private var durationSeconds: Int = 0

    @State private var isShowingConfirmation = false
    @State private var pendingConfirmationAction: Action? = nil
    @State private var action: Action? = nil
    
    private var isNameValid: Bool {
        name.wholeMatch(of: /.{1, 16}/) != nil
    }

    private var isDurationValid: Bool {
        durationSeconds > 0
    }
    
    private var isValid: Bool {
        isNameValid && isDurationValid && outlet != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                ValidatingView(
                    validatingField: { TextField("Name", text: $name) },
                    validationText: "1-16 characters",
                    isValid: isNameValid
                )
                if let outlet {
                    OutletPicker(outlets: device.outletsSortedBySlot, selected: $outlet)
                        .pickerStyle(.segmented)

                    if let temperatureRange = outlet.temperatureRange {
                        VStack {
                            Label("Temperature", systemImage: "thermometer")
                            ZStack {
                                TemperatureCirclePicker(
                                    temperature: $targetTemperature,
                                    permittedRange: temperatureRange
                                )
                                .frame(width: 200, height: 200)

                                TemperatureText(temperature: targetTemperature)
                                    .font(.largeTitle)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    ValidatingView(
                        validatingField: {
                            DurationPicker(
                                labelText: "Duration",
                                seconds: $durationSeconds,
                                maximumSeconds: outlet.maximumDurationSeconds
                            )
                            .frame(width: 200, height: 200)
                        },
                        validationText: "Greater than zero",
                        isValid: isDurationValid
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                let isDefault = preset?.presetSlot == device.defaultPresetSlot
                if !isDefault {
                    Section {
                        Button("Make Default") { triggerAction(.persistPreset(makeDefault: true)) }
                            .disabled(!isValid)
                        Button("Delete", role: .destructive) { triggerAction(.deletePreset) }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { triggerAction(.persistPreset(makeDefault: false)) }
                        .disabled(!isValid)
                }
            }
            .deviceLockoutConfirmationDialog(
                $isShowingConfirmation,
                device: device,
                confirmAction: actionConfirmed
            )
            .operationInProgress(action != nil)
            .navigationTitle("Preset")
            .navigationBarBackButtonHidden()
        }
        .task {
            if let preset {
                name = preset.name
                outlet = preset.outlet
                targetTemperature = preset.targetTemperature
                durationSeconds = preset.durationSeconds
            } else if let lastOutlet = device.outletsSortedBySlot.last {
                outlet = lastOutlet
                targetTemperature = lastOutlet.minimumTemperature
            }
        }
        .task(id: action) {
            if let action {
                switch action {
                case .persistPreset(let makeDefault):
                    await persistPreset(makeDefault: makeDefault)
                    
                case .deletePreset:
                    await deletePreset()
                }
                
                self.action = nil
            }
        }
    }
    
    func triggerAction(_ action: Action) {
        if device.isStopped {
            self.action = action
        } else {
            pendingConfirmationAction = action
            isShowingConfirmation = true
        }
    }
    
    func actionConfirmed() {
        action = pendingConfirmationAction
        pendingConfirmationAction = nil
        isShowingConfirmation = false
    }
    
    func persistPreset(makeDefault: Bool) async {
        await tools.alertOnError {
            if let outlet {
                if let preset {
                    try await tools.deviceService.updatePresetDetails(
                        device.id,
                        presetSlot: preset.presetSlot,
                        name: name,
                        outletSlot: outlet.outletSlot,
                        targetTemperature: targetTemperature,
                        durationSeconds: durationSeconds,
                        makeDefault: makeDefault
                    )
                } else {
                    try await tools.deviceService.createPresetDetails(
                        device.id,
                        name: name,
                        outletSlot: outlet.outletSlot,
                        targetTemperature: targetTemperature,
                        durationSeconds: durationSeconds,
                        makeDefault: makeDefault
                    )
                }
            }
            dismiss()
        }
    }
    
    func deletePreset() async{
        if let preset {
            await tools.alertOnError {
                try await tools.deviceService.deletePresetDetails(device.id, presetSlot: preset.presetSlot)
                dismiss()
            }
        }
    }
}

#Preview {
    @Previewable @State var preset: Preset? = PreviewData.data.device.presets[0]
    Preview {
        return EditPresetView(
            device: PreviewData.data.device,
            preset: $preset
        )
    }
}
