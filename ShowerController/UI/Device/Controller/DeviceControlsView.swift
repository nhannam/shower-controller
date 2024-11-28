//
//  DeviceControlsView.swift
//  ShowerController
//
//  Created by Nigel Hannam on 17/10/2024.
//

import SwiftUI
import SwiftData

struct DeviceControlsView: View {
    private static let logger = LoggerFactory.logger(DeviceControlsView.self)
    
    @Environment(Toolbox.self) private var tools

    var device: Device
    
    @State private var temperature: Double = Device.permittedTemperatureRange.lowerBound

    @State private var isEditingTemperature = false
    @State private var isSubmitted = false
    
    var displayTemperature: Double {
        if device.isWaterFlowing {
            device.targetTemperature
        } else {
            device.selectedTemperature
        }
    }

    var body: some View {
        HStack {
            let outlet0 = device.outlets.first(where: { $0.outletSlot == Outlet.outletSlot0 })
            let outlet1 = device.outlets.first(where: { $0.outletSlot == Outlet.outletSlot1 })
            
            Spacer()
            
            VStack {
                ZStack {
                    Grid {
                        DurationText(
                            seconds: device.secondsRemaining
                        )
                        .foregroundStyle(device.runningState == .paused ? .gray : .black)
                        .frame(alignment: .top)
                        .font(.largeTitle)
                        
                        GridRow {
                            if let outlet0 {
                                OutletButton(device: device, outlet: outlet0)
                            }

                            if let outlet1 {
                                Spacer()
                                OutletButton(device: device, outlet: outlet1)
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
                                    onTemperatureSelected(temperature: temperature)
                                }
                                isEditingTemperature = editing
                            }
                        )
                        
                        Group {
                            var isCold: Bool {
                                if isEditingTemperature || isSubmitted || !device.isWaterFlowing {
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
    }
    
    func onTemperatureSelected(temperature: Double) {
        isSubmitted = true
        tools.submitJobWithErrorHandler {
            try await tools.deviceService.updateSelectedTemperature(
                device.id,
                targetTemperature: temperature
            )
        } finally: {
            isSubmitted = false
        }
    }
}

#Preview {
    Preview {
        DeviceControlsView(
            device: PreviewData.data.device
        )
    }
}
