//
//  DeviceControllerView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI
import SwiftData

struct DeviceControllerView: View {
    private static let logger = LoggerFactory.logger(DeviceControllerView.self)
    
    @Environment(Toolbox.self) private var tools

    var device: Device
    
    @State private var temperature: Double = Device.permittedTemperatureRange.lowerBound
    @State private var submittedTemperature: Double? = nil

    @State private var isEditingTemperature = false
    
    var displayTemperature: Double {
        if device.isWaterFlowing {
            device.targetTemperature
        } else {
            device.selectedTemperature
        }
    }

    var body: some View {
        HStack {
            Spacer()
            
            VStack {
                ZStack {
                    Grid {
                        DurationText(
                            seconds: device.secondsRemaining
                        )
                        .foregroundStyle(device.runningState == .paused ? .gray : .black)
                        .padding(.top, 10)
                        .padding(.bottom, 1)
                        .font(.largeTitle)
                        
                        GridRow {
                            ForEach(device.userInterface?.buttons.sorted(by: \.buttonSlot) ?? []) { button in
                                ControllerButton(device: device, userInterfaceButton: button)
                                    .padding(.horizontal, 10)
                                    .frame(maxHeight: 140)
                            }
                        }
                        
                        Spacer()
                    }
                    .frame(width: 250, height: 250)
                    
                    let activeOutlet = device.activeOutlet
                    if let activeOutlet {
                        TemperatureCirclePicker(
                            temperature: $temperature,
                            permittedRange: activeOutlet.temperatureRange ?? Device.permittedTemperatureRange,
                            onEditingChanged: { editing in
                                if (!editing) {
                                    submittedTemperature = temperature
                                }
                                isEditingTemperature = editing
                            }
                        )
                        
                        Group {
                            var isCold: Bool {
                                if isEditingTemperature || submittedTemperature != nil || !device.isWaterFlowing {
                                    device.getRunningStateForTemperature(
                                        temperature: temperature,
                                        outlet: activeOutlet
                                    ) == .cold
                                } else {
                                    device.runningState == .cold
                                }
                            }

                            if isCold {
                                Text("Cold")
                            } else {
                                TemperatureText(temperature: temperature)
                            }
                        }
                        .font(.largeTitle)
                        .offset(y: 120)
                    }
                }
            }
            .disabled(device.isLockedOut)
            .frame(width: 300, height: 300)

            Spacer()
        }
        .onChange(of: displayTemperature, initial: true) { _, newValue in
            temperature = newValue
        }
        .task(id: submittedTemperature) {
            if let submittedTemperature {
                await updatedSelectedTemperature(temperature: submittedTemperature)
                self.submittedTemperature = nil
            }
        }
    }
    
    func updatedSelectedTemperature(temperature: Double) async {
        await tools.alertOnError {
            try await tools.deviceService.updateSelectedTemperature(
                device.id,
                targetTemperature: temperature
            )
        }
    }
}

#Preview {
    Preview {
        DeviceControllerView(
            device: PreviewData.data.device
        )
    }
}
