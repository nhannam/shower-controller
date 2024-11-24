//
//  EditOutletSettingsView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI

struct EditOutletSettingsView: View {
    private static let logger = LoggerFactory.logger(EditOutletSettingsView.self)

    @Environment(\.dismiss) private var dismiss
    @Environment(Toolbox.self) private var tools

    var device: Device

    var outlet: Outlet

    @State private var minimumTemperature: Double = 0
    @State private var maximumTemperature: Double = 0
    @State private var maximumDurationSeconds: Int = 0

    @State private var isShowingConfirmation =  false
    @State private var isSubmitted =  false

    private var isTemperatureRangeValid: Bool {
        return minimumTemperature < maximumTemperature
    }

    private var isMaximumDurationValid: Bool {
        maximumDurationSeconds > 0
    }

    private var isValid: Bool {
        return isTemperatureRangeValid && isMaximumDurationValid
    }

    var body: some View {
        NavigationStack {
            Form {
                ValidatingView(
                    validatingField: {
                        HStack {
                            Spacer()
                            VStack {
                                Label("Minimum", systemImage: "thermometer")
                                TemperatureCirclePicker(
                                    temperature: $minimumTemperature,
                                    temperatureRange: Outlet.minimumPermittedTemperature...Outlet.maximumPermittedTemperature
                                )
                                .frame(width: 150, height: 150)
                            }
                            Spacer()
                            VStack {
                                Label("Maximum", systemImage: "thermometer")
                                TemperatureCirclePicker(
                                    temperature: $maximumTemperature,
                                    temperatureRange: Outlet.minimumPermittedTemperature...Outlet.maximumPermittedTemperature
                                )
                                .frame(width: 150, height: 150)
                            }
                            Spacer()
                        }
                    },
                    validationText: "Maximum > minimum ",
                    isValid: isTemperatureRangeValid
                )
                ValidatingView(
                    validatingField: {
                        DurationPicker(
                            labelText: "Duration",
                            seconds: $maximumDurationSeconds,
                            maximumSeconds: Outlet.maximumPermittedDurationSeconds
                        )
                        .frame(width: 200, height: 200)
                    },
                    validationText: "Greater than zero",
                    isValid: isMaximumDurationValid
                )
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if device.isTimerRunning {
                            isShowingConfirmation = true
                        } else {
                            persist()
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .deviceLockoutConfirmationDialog(
                $isShowingConfirmation,
                device: device,
                confirmAction: persist
            )
            .operationInProgress(isSubmitted)
            .navigationTitle(outlet.type.description)
            .navigationBarBackButtonHidden()
        }
        .task {
            minimumTemperature = outlet.minimumTemperature
            maximumTemperature = outlet.maximumTemperature
            maximumDurationSeconds = outlet.maximumDurationSeconds
        }
    }
    
    func persist() {
        isSubmitted = true
        tools.submitJobWithErrorHandler {
            try await tools.deviceService.updateOutletSettings(
                device.id,
                outletSlot: outlet.outletSlot,
                temperatureRange: minimumTemperature...maximumTemperature,
                maximumDurationSeconds: maximumDurationSeconds
            )
            dismiss()
        } finally: {
            isSubmitted = false
        }
    }
}

#Preview {
    Preview {
        EditOutletSettingsView(
            device: PreviewData.data.device,
            outlet: PreviewData.data.device.outlets[0]
        )
    }
}
