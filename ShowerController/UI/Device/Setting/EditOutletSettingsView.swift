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

    @State private var minimumTemperature: Double = Device.permittedTemperatureRange.lowerBound
    @State private var maximumTemperature: Double = Device.permittedTemperatureRange.upperBound
    @State private var maximumDurationSeconds: Int = Device.maximumPermittedDurationSeconds

    @State private var isShowingConfirmation =  false
    @State private var isSubmitted =  false
    
    private var isTemperatureRangeValid: Bool {
        minimumTemperature < maximumTemperature
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
                                Label("Temperature Range", systemImage: "thermometer")
                                TemperatureRangeCirclePicker(
                                    lowerTemperature: $minimumTemperature,
                                    upperTemperature: $maximumTemperature,
                                    permittedRange: Device.permittedTemperatureRange
                                )
                                .frame(width: 200, height: 200)
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
                            labelText: "Max Duration",
                            seconds: $maximumDurationSeconds,
                            maximumSeconds: Device.maximumPermittedDurationSeconds
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
                        if !device.isStopped {
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
